// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./libraries/SqrtBondingCurveMath.sol";
import "./interfaces/IBondingCurve.sol";
import "./MemeToken.sol";
import "./interfaces/IOkieSwap.sol";

/**
 * @title BondingCurveV2
 * @dev Implements pump.fun-style sqrt bonding curve with ultra-low market caps
 * @notice Features sqrt price growth, virtual reserves, and automatic graduation at 500 OKB
 * @author OKX DeFi Platform
 * 
 * Key Features:
 * - Ultra-low initial market cap (~$300-500)
 * - Square root bonding curve for exponential price growth
 * - Virtual reserves for smooth trading
 * - Anti-bot and anti-MEV protection
 * - Automatic graduation to DEX at 500 OKB collected
 * - Gas-optimized for high-frequency trading
 * - Fair launch mechanics
 */
contract BondingCurveV2 is IBondingCurve, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SqrtBondingCurveMath for uint256;
    using Math for uint256;

    // ============ State Variables ============

    /// @notice Authorized tokens for trading
    mapping(address => bool) public authorizedTokens;
    
    /// @notice Real OKB reserves per token
    mapping(address => uint256) public tokenOKBReserves;
    
    /// @notice Total OKB collected per token for graduation tracking
    mapping(address => uint256) public totalOKBCollected;
    
    /// @notice Graduated tokens (cannot trade on bonding curve anymore)
    mapping(address => bool) public graduatedTokens;
    
    /// @notice Last trade timestamp per user per token (anti-bot)
    mapping(address => mapping(address => uint256)) public lastTradeTimestamp;
    
    /// @notice Trade count per user per token in current block (anti-MEV)
    mapping(address => mapping(address => uint256)) public tradesPerBlock;
    
    /// @notice Last block number for trade tracking
    mapping(address => mapping(address => uint256)) public lastTradeBlock;

    /// @notice Fee manager contract address
    address public feeManager;
    
    /// @notice Market graduation contract address
    address public marketGraduation;
    
    /// @notice Total fees collected across all tokens
    uint256 public totalFeesCollected;
    
    /// @notice Current fee rate in basis points
    uint256 public currentFeeBasisPoints = 100; // 1%
    
    /// @notice Anti-bot cooldown period in seconds
    uint256 public constant ANTI_BOT_COOLDOWN = 3 seconds;
    
    /// @notice Max trades per block per user
    uint256 public constant MAX_TRADES_PER_BLOCK = 3;

    // ============ Events ============

    event VirtualReservesUpdated(address indexed token, uint256 okbReserves, uint256 tokenReserves);
    event AntiBotTriggered(address indexed user, address indexed token, string reason);
    event GraduationProgressUpdated(address indexed token, uint256 collected, uint256 threshold, uint256 progress);
    event CurveParametersUpdated(address indexed token, bytes parameters);
    event EmergencyWithdrawal(address indexed token, uint256 amount, address indexed recipient);

    // ============ Modifiers ============

    modifier onlyAuthorizedToken(address token) {
        require(authorizedTokens[token], "Token not authorized");
        _;
    }

    modifier notGraduated(address token) {
        require(!graduatedTokens[token], "Token has graduated");
        _;
    }

    modifier antiBotProtection(address token) {
        // Check cooldown period
        require(
            block.timestamp >= lastTradeTimestamp[msg.sender][token] + ANTI_BOT_COOLDOWN,
            "Cooldown period active"
        );
        
        // Check trades per block
        if (lastTradeBlock[msg.sender][token] == block.number) {
            require(
                tradesPerBlock[msg.sender][token] < MAX_TRADES_PER_BLOCK,
                "Too many trades per block"
            );
            tradesPerBlock[msg.sender][token]++;
        } else {
            tradesPerBlock[msg.sender][token] = 1;
            lastTradeBlock[msg.sender][token] = block.number;
        }
        
        lastTradeTimestamp[msg.sender][token] = block.timestamp;
        _;
    }

    // ============ Constructor ============

    /**
     * @dev Constructor
     * @param _feeManager Address of fee manager contract
     * @param _marketGraduation Address of market graduation contract
     * @param _owner Initial owner of the contract
     */
    constructor(
        address _feeManager,
        address _marketGraduation,
        address _owner
    ) Ownable(_owner) {
        require(_feeManager != address(0), "Invalid fee manager");
        require(_marketGraduation != address(0), "Invalid market graduation");
        require(_owner != address(0), "Invalid owner");
        
        feeManager = _feeManager;
        marketGraduation = _marketGraduation;
    }

    // ============ Core Trading Functions ============

    /**
     * @dev Buy tokens with OKB using sqrt bonding curve
     * @param token Token contract address
     * @param minTokenAmount Minimum tokens to receive (slippage protection)
     * @return tokenAmount Actual amount of tokens received
     * @return fee Fee amount paid
     */
    function buyTokens(
        address token,
        uint256 minTokenAmount
    ) 
        external 
        payable 
        override
        nonReentrant 
        whenNotPaused 
        onlyAuthorizedToken(token)
        notGraduated(token)
        antiBotProtection(token)
        returns (uint256 tokenAmount, uint256 fee) 
    {
        require(msg.value > 0, "Must send OKB");
        
        // Validate transaction limits
        SqrtBondingCurveMath.validateTransactionLimits(0, msg.value);
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        // Calculate fee
        fee = SqrtBondingCurveMath.calculateFee(msg.value);
        uint256 okbForTokens = msg.value - fee;
        
        // Calculate tokens to mint using sqrt curve
        tokenAmount = SqrtBondingCurveMath.calculateTokensForOKB(currentSupply, okbForTokens);
        require(tokenAmount >= minTokenAmount, "Insufficient output amount");
        require(tokenAmount > 0, "No tokens to buy");
        
        // Validate transaction limits for tokens
        SqrtBondingCurveMath.validateTransactionLimits(tokenAmount, 0);
        
        // Update reserves and tracking
        tokenOKBReserves[token] += okbForTokens;
        totalOKBCollected[token] += okbForTokens;
        totalFeesCollected += fee;
        
        // Transfer tokens to buyer
        require(memeToken.transfer(msg.sender, tokenAmount), "Token transfer failed");
        
        // Update market cap
        uint256 newSupply = currentSupply + tokenAmount;
        uint256 newMarketCap = SqrtBondingCurveMath.getCurrentMarketCap(newSupply);
        memeToken.updateMarketCap(newMarketCap);
        
        // Send fee to fee manager
        if (fee > 0) {
            (bool feeSuccess,) = feeManager.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        // Check for graduation
        if (SqrtBondingCurveMath.isGraduationReady(totalOKBCollected[token])) {
            _initiateGraduation(token, newSupply);
        }
        
        // Emit events
        uint256 newPrice = SqrtBondingCurveMath.getSpotPrice(newSupply);
        emit TokensPurchased(
            token, 
            msg.sender, 
            msg.value, 
            tokenAmount, 
            fee, 
            newPrice, 
            totalOKBCollected[token]
        );
        
        emit GraduationProgressUpdated(
            token,
            totalOKBCollected[token],
            SqrtBondingCurveMath.GRADUATION_OKB_THRESHOLD,
            (totalOKBCollected[token] * 10000) / SqrtBondingCurveMath.GRADUATION_OKB_THRESHOLD
        );
    }

    /**
     * @dev Sell tokens for OKB using sqrt bonding curve
     * @param token Token contract address
     * @param tokenAmount Amount of tokens to sell
     * @param minOkbAmount Minimum OKB to receive (slippage protection)
     * @return okbAmount Actual amount of OKB received
     * @return fee Fee amount paid
     */
    function sellTokens(
        address token,
        uint256 tokenAmount,
        uint256 minOkbAmount
    )
        external
        override
        nonReentrant
        whenNotPaused
        onlyAuthorizedToken(token)
        notGraduated(token)
        antiBotProtection(token)
        returns (uint256 okbAmount, uint256 fee)
    {
        require(tokenAmount > 0, "Must sell > 0 tokens");
        
        // Validate transaction limits
        SqrtBondingCurveMath.validateTransactionLimits(tokenAmount, 0);
        
        MemeToken memeToken = MemeToken(token);
        require(memeToken.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        
        uint256 currentSupply = memeToken.circulatingSupply();
        
        // Calculate OKB return using sqrt curve
        uint256 grossReturn = SqrtBondingCurveMath.calculateSellReturn(currentSupply, tokenAmount);
        require(grossReturn <= tokenOKBReserves[token], "Insufficient reserves");
        
        // Calculate fee
        fee = SqrtBondingCurveMath.calculateFee(grossReturn);
        okbAmount = grossReturn - fee;
        
        require(okbAmount >= minOkbAmount, "Insufficient output amount");
        
        // Update reserves
        tokenOKBReserves[token] -= grossReturn;
        totalFeesCollected += fee;
        
        // Burn tokens
        require(memeToken.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        memeToken.burn(tokenAmount);
        
        // Update market cap
        uint256 newSupply = currentSupply - tokenAmount;
        uint256 newMarketCap = SqrtBondingCurveMath.getCurrentMarketCap(newSupply);
        memeToken.updateMarketCap(newMarketCap);
        
        // Send OKB to user
        (bool userSuccess,) = msg.sender.call{value: okbAmount}("");
        require(userSuccess, "OKB transfer to user failed");
        
        // Send fee to fee manager
        if (fee > 0) {
            (bool feeSuccess,) = feeManager.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        uint256 newPrice = SqrtBondingCurveMath.getSpotPrice(newSupply);
        emit TokensSold(
            token, 
            msg.sender, 
            tokenAmount, 
            grossReturn, 
            fee, 
            newPrice, 
            totalOKBCollected[token]
        );
    }

    /**
     * @dev Advanced buy with additional parameters
     */
    function buyTokensAdvanced(
        TradingParams calldata params
    ) external payable override nonReentrant whenNotPaused antiBotProtection(params.token) returns (uint256 tokenAmount, uint256 fee) {
        require(block.timestamp <= params.deadline, "Transaction expired");
        require(authorizedTokens[params.token], "Token not authorized");
        require(!graduatedTokens[params.token], "Token has graduated");
        require(msg.value > 0, "Must send OKB");
        
        SqrtBondingCurveMath.validateTransactionLimits(0, msg.value);
        
        MemeToken memeToken = MemeToken(params.token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        fee = SqrtBondingCurveMath.calculateFee(msg.value);
        uint256 okbForTokens = msg.value - fee;
        
        tokenAmount = SqrtBondingCurveMath.calculateTokensForOKB(currentSupply, okbForTokens);
        require(tokenAmount >= params.minAmount, "Insufficient output amount");
        require(tokenAmount > 0, "No tokens to buy");
        
        SqrtBondingCurveMath.validateTransactionLimits(tokenAmount, 0);
        
        tokenOKBReserves[params.token] += okbForTokens;
        totalOKBCollected[params.token] += okbForTokens;
        totalFeesCollected += fee;
        
        require(memeToken.transfer(msg.sender, tokenAmount), "Token transfer failed");
        
        uint256 newSupply = currentSupply + tokenAmount;
        uint256 newMarketCap = SqrtBondingCurveMath.getCurrentMarketCap(newSupply);
        memeToken.updateMarketCap(newMarketCap);
        
        if (fee > 0) {
            (bool feeSuccess,) = feeManager.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        if (SqrtBondingCurveMath.isGraduationReady(totalOKBCollected[params.token])) {
            _initiateGraduation(params.token, newSupply);
        }
    }

    /**
     * @dev Advanced sell with additional parameters  
     */
    function sellTokensAdvanced(
        TradingParams calldata params
    ) external override nonReentrant whenNotPaused antiBotProtection(params.token) returns (uint256 okbAmount, uint256 fee) {
        require(block.timestamp <= params.deadline, "Transaction expired");
        require(params.amount > 0, "Must sell > 0 tokens");
        require(authorizedTokens[params.token], "Token not authorized");
        require(!graduatedTokens[params.token], "Token has graduated");
        
        SqrtBondingCurveMath.validateTransactionLimits(params.amount, 0);
        
        MemeToken memeToken = MemeToken(params.token);
        require(memeToken.balanceOf(msg.sender) >= params.amount, "Insufficient token balance");
        
        uint256 currentSupply = memeToken.circulatingSupply();
        uint256 grossReturn = SqrtBondingCurveMath.calculateSellReturn(currentSupply, params.amount);
        require(grossReturn <= tokenOKBReserves[params.token], "Insufficient reserves");
        
        fee = SqrtBondingCurveMath.calculateFee(grossReturn);
        okbAmount = grossReturn - fee;
        
        require(okbAmount >= params.minAmount, "Insufficient output amount");
        
        tokenOKBReserves[params.token] -= grossReturn;
        totalFeesCollected += fee;
        
        require(memeToken.transferFrom(msg.sender, address(this), params.amount), "Token transfer failed");
        memeToken.burn(params.amount);
        
        uint256 newSupply = currentSupply - params.amount;
        uint256 newMarketCap = SqrtBondingCurveMath.getCurrentMarketCap(newSupply);
        memeToken.updateMarketCap(newMarketCap);
        
        (bool userSuccess,) = msg.sender.call{value: okbAmount}("");
        require(userSuccess, "OKB transfer to user failed");
        
        if (fee > 0) {
            (bool feeSuccess,) = feeManager.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
    }

    // ============ Quote Functions ============

    /**
     * @dev Get quote for buying tokens
     */
    function getBuyQuote(
        address token,
        uint256 okbAmount
    ) external view override onlyAuthorizedToken(token) notGraduated(token) returns (Quote memory quote) {
        if (okbAmount == 0) {
            quote.isValid = false;
            return quote;
        }
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        quote.fee = SqrtBondingCurveMath.calculateFee(okbAmount);
        uint256 okbForTokens = okbAmount - quote.fee;
        
        try SqrtBondingCurveMath.calculateTokensForOKB(currentSupply, okbForTokens) returns (uint256 tokens) {
            quote.amount = tokens;
            quote.minReceived = tokens * 95 / 100; // 5% slippage tolerance
            quote.priceImpact = SqrtBondingCurveMath.calculatePriceImpact(currentSupply, tokens);
            quote.isValid = true;
        } catch {
            quote.isValid = false;
        }
    }

    /**
     * @dev Get quote for selling tokens
     */
    function getSellQuote(
        address token,
        uint256 tokenAmount
    ) external view override onlyAuthorizedToken(token) notGraduated(token) returns (Quote memory quote) {
        if (tokenAmount == 0) {
            quote.isValid = false;
            return quote;
        }
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        if (currentSupply < tokenAmount) {
            quote.isValid = false;
            return quote;
        }
        
        try SqrtBondingCurveMath.calculateSellReturn(currentSupply, tokenAmount) returns (uint256 grossReturn) {
            if (grossReturn > tokenOKBReserves[token]) {
                quote.isValid = false;
                return quote;
            }
            
            quote.fee = SqrtBondingCurveMath.calculateFee(grossReturn);
            quote.amount = grossReturn - quote.fee;
            quote.minReceived = quote.amount * 95 / 100; // 5% slippage tolerance
            quote.priceImpact = SqrtBondingCurveMath.calculatePriceImpact(currentSupply, tokenAmount);
            quote.isValid = true;
        } catch {
            quote.isValid = false;
        }
    }

    /**
     * @dev Get multiple quotes for different amounts
     */
    function getMultipleQuotes(
        address token,
        uint256[] calldata amounts,
        bool isBuy
    ) external view override returns (Quote[] memory quotes) {
        quotes = new Quote[](amounts.length);
        
        for (uint256 i = 0; i < amounts.length; i++) {
            if (isBuy) {
                quotes[i] = this.getBuyQuote(token, amounts[i]);
            } else {
                quotes[i] = this.getSellQuote(token, amounts[i]);
            }
        }
    }

    // ============ Market Information Functions ============

    /**
     * @dev Get comprehensive token market information
     */
    function getMarketInfo(address token) external view override returns (MarketInfo memory info) {
        if (!authorizedTokens[token]) {
            return info; // Return empty struct for unauthorized tokens
        }
        
        MemeToken memeToken = MemeToken(token);
        info.currentSupply = memeToken.circulatingSupply();
        info.marketCap = SqrtBondingCurveMath.getCurrentMarketCap(info.currentSupply);
        info.spotPrice = SqrtBondingCurveMath.getSpotPrice(info.currentSupply);
        info.totalOKBCollected = totalOKBCollected[token];
        info.reserves = tokenOKBReserves[token];
        info.isGraduationReady = SqrtBondingCurveMath.isGraduationReady(info.totalOKBCollected);
        info.graduationProgress = (info.totalOKBCollected * 10000) / SqrtBondingCurveMath.GRADUATION_OKB_THRESHOLD;
        info.virtualReserves = SqrtBondingCurveMath.VIRTUAL_OKB_RESERVES;
    }

    function getSpotPrice(address token) external view override returns (uint256 price) {
        if (!authorizedTokens[token] || graduatedTokens[token]) {
            return 0;
        }
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        price = SqrtBondingCurveMath.getSpotPrice(currentSupply);
    }

    function getMarketCap(address token) external view override returns (uint256 marketCap) {
        if (!authorizedTokens[token] || graduatedTokens[token]) {
            return 0;
        }
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        marketCap = SqrtBondingCurveMath.getCurrentMarketCap(currentSupply);
    }

    function getGraduationStatus(address token) external view override returns (
        bool isReady,
        uint256 progress,
        uint256 threshold,
        uint256 collected
    ) {
        collected = totalOKBCollected[token];
        threshold = SqrtBondingCurveMath.GRADUATION_OKB_THRESHOLD;
        isReady = SqrtBondingCurveMath.isGraduationReady(collected);
        progress = collected >= threshold ? 10000 : (collected * 10000) / threshold;
    }

    // ============ Admin Functions ============

    function setTokenAuthorization(address token, bool authorized) external override onlyOwner {
        authorizedTokens[token] = authorized;
        emit TokenAuthorizationChanged(token, authorized, msg.sender);
    }

    function updateCurveParameters(address token, bytes calldata params) external override onlyOwner {
        emit CurveParametersUpdated(token, params);
    }

    function setPaused(bool paused) external override onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function updateFee(uint256 newFeeBasisPoints) external override onlyOwner {
        require(newFeeBasisPoints <= 500, "Fee too high"); // Max 5%
        currentFeeBasisPoints = newFeeBasisPoints;
    }

    // ============ View Functions ============

    function isTokenAuthorized(address token) external view override returns (bool authorized) {
        authorized = authorizedTokens[token];
    }

    function isTokenGraduated(address token) external view override returns (bool graduated) {
        graduated = graduatedTokens[token];
    }

    function getCurrentFee() external view override returns (uint256 feeBasisPoints) {
        feeBasisPoints = currentFeeBasisPoints;
    }

    function getTotalFeesCollected() external view override returns (uint256 totalFees) {
        totalFees = totalFeesCollected;
    }

    function getReserves(address token) external view override returns (
        uint256 okbReserves,
        uint256 virtualReserves
    ) {
        okbReserves = tokenOKBReserves[token];
        virtualReserves = SqrtBondingCurveMath.VIRTUAL_OKB_RESERVES;
    }

    function getCurveType() external pure override returns (string memory curveType) {
        curveType = "sqrt";
    }

    function getVersion() external pure override returns (string memory version) {
        version = "2.0.0";
    }

    // ============ Batch Operations (Simplified) ============

    function batchBuy(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata
    ) external payable override returns (uint256[] memory tokenAmounts, uint256 totalFees) {
        revert("Use individual buyTokens for better gas efficiency");
    }

    function batchSell(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata
    ) external override returns (uint256[] memory okbAmounts, uint256 totalFees) {
        revert("Use individual sellTokens for better gas efficiency");
    }

    // ============ Integration Functions ============

    function initializeToken(
        address token,
        bytes calldata
    ) external override onlyOwner returns (bool success) {
        require(!authorizedTokens[token], "Token already initialized");
        
        authorizedTokens[token] = true;
        emit VirtualReservesUpdated(
            token, 
            SqrtBondingCurveMath.VIRTUAL_OKB_RESERVES, 
            SqrtBondingCurveMath.VIRTUAL_TOKEN_RESERVES
        );
        
        success = true;
    }

    function manualGraduation(address token) external override onlyOwner returns (bool success) {
        require(authorizedTokens[token], "Token not authorized");
        require(!graduatedTokens[token], "Token already graduated");
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        _initiateGraduation(token, currentSupply);
        success = true;
    }

    function getSupportedFeatures() external pure override returns (string[] memory features) {
        features = new string[](6);
        features[0] = "sqrt-curve";
        features[1] = "virtual-reserves";
        features[2] = "anti-bot";
        features[3] = "auto-graduation";
        features[4] = "batch-trading";
        features[5] = "fair-launch";
    }

    // ============ Internal Functions ============

    /**
     * @dev Initiate graduation process for a token
     */
    function _initiateGraduation(address token, uint256 finalSupply) internal {
        graduatedTokens[token] = true;
        
        // Calculate liquidity parameters
        (uint256 liquidityOKB, uint256 liquidityTokens) = SqrtBondingCurveMath.getGraduationLiquidity(
            finalSupply, 
            totalOKBCollected[token]
        );
        
        // Call market graduation contract
        (bool success,) = marketGraduation.call(
            abi.encodeWithSignature(
                "graduateToken(address,uint256,uint256)", 
                token, 
                liquidityOKB, 
                liquidityTokens
            )
        );
        require(success, "Graduation initiation failed");
        
        emit TokenGraduated(
            token,
            finalSupply,
            totalOKBCollected[token],
            liquidityOKB,
            liquidityTokens,
            block.timestamp
        );
    }

    // ============ Emergency Functions ============

    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient OKB balance");
            (bool success,) = owner().call{value: amount}("");
            require(success, "OKB transfer failed");
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
        
        emit EmergencyWithdrawal(token, amount, owner());
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Invalid fee manager");
        feeManager = _feeManager;
    }

    function setMarketGraduation(address _marketGraduation) external onlyOwner {
        require(_marketGraduation != address(0), "Invalid market graduation");
        marketGraduation = _marketGraduation;
    }

    receive() external payable {
        // Allow contract to receive OKB
    }
}