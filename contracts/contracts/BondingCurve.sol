// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/BondingCurveMath.sol";
import "./MemeToken.sol";
import "./interfaces/IOkieSwap.sol";

/**
 * @title BondingCurve
 * @dev Implements bonding curve trading for meme tokens
 * @notice Manages token buying/selling with linear bonding curve until graduation
 */
contract BondingCurve is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using BondingCurveMath for uint256;

    // State variables
    mapping(address => bool) public authorizedTokens;
    mapping(address => uint256) public tokenReserves; // OKB reserves per token
    mapping(address => bool) public graduatedTokens;
    
    address public feeManager;
    address public marketGraduation;
    uint256 public totalFeesCollected;
    
    // Events
    event TokenBought(
        address indexed token,
        address indexed buyer,
        uint256 okbAmount,
        uint256 tokenAmount,
        uint256 fee,
        uint256 newPrice
    );
    
    event TokenSold(
        address indexed token,
        address indexed seller,
        uint256 tokenAmount,
        uint256 okbAmount,
        uint256 fee,
        uint256 newPrice
    );
    
    event TokenGraduated(
        address indexed token,
        uint256 finalMarketCap,
        uint256 timestamp
    );
    
    event TokenAuthorized(address indexed token, bool authorized);
    event ReservesUpdated(address indexed token, uint256 newReserves);
    
    /**
     * @dev Constructor
     * @param _feeManager Address of fee manager contract
     * @param _marketGraduation Address of market graduation contract
     */
    constructor(
        address _feeManager,
        address _marketGraduation
    ) {
        require(_feeManager != address(0), "Invalid fee manager");
        require(_marketGraduation != address(0), "Invalid market graduation");
        
        feeManager = _feeManager;
        marketGraduation = _marketGraduation;
    }
    
    /**
     * @dev Authorize a token for bonding curve trading
     * @param token Token contract address
     * @param authorized Whether to authorize or deauthorize
     */
    function setTokenAuthorization(address token, bool authorized) external onlyOwner {
        authorizedTokens[token] = authorized;
        emit TokenAuthorized(token, authorized);
    }
    
    /**
     * @dev Buy tokens with OKB using bonding curve
     * @param token Token contract address
     * @param minTokenAmount Minimum tokens to receive (slippage protection)
     */
    function buyTokens(
        address token,
        uint256 minTokenAmount
    ) external payable nonReentrant whenNotPaused {
        require(authorizedTokens[token], "Token not authorized");
        require(!graduatedTokens[token], "Token has graduated");
        require(msg.value > 0, "Must send OKB");
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        // Calculate fee
        uint256 fee = BondingCurveMath.calculateFee(msg.value, false);
        uint256 okbForTokens = msg.value - fee;
        
        // Calculate tokens to mint
        uint256 tokenAmount = BondingCurveMath.calculateTokensForOKB(currentSupply, okbForTokens);
        require(tokenAmount >= minTokenAmount, "Insufficient output amount");
        require(tokenAmount > 0, "No tokens to buy");
        
        // Update reserves
        tokenReserves[token] += okbForTokens;
        totalFeesCollected += fee;
        
        // Transfer tokens to buyer
        memeToken.transfer(msg.sender, tokenAmount);
        
        // Update market cap
        uint256 newSupply = currentSupply + tokenAmount;
        uint256 newMarketCap = BondingCurveMath.getCurrentMarketCap(newSupply);
        memeToken.updateMarketCap(newMarketCap);
        
        // Send fee to fee manager
        if (fee > 0) {
            (bool success,) = feeManager.call{value: fee}("");
            require(success, "Fee transfer failed");
        }
        
        // Check for graduation
        if (BondingCurveMath.isGraduationReady(newSupply)) {
            _initiateGraduation(token);
        }
        
        uint256 newPrice = BondingCurveMath.getSpotPrice(newSupply);
        emit TokenBought(token, msg.sender, msg.value, tokenAmount, fee, newPrice);
    }
    
    /**
     * @dev Sell tokens for OKB using bonding curve
     * @param token Token contract address
     * @param tokenAmount Amount of tokens to sell
     * @param minOkbAmount Minimum OKB to receive (slippage protection)
     */
    function sellTokens(
        address token,
        uint256 tokenAmount,
        uint256 minOkbAmount
    ) external nonReentrant whenNotPaused {
        require(authorizedTokens[token], "Token not authorized");
        require(!graduatedTokens[token], "Token has graduated");
        require(tokenAmount > 0, "Must sell > 0 tokens");
        
        MemeToken memeToken = MemeToken(token);
        require(memeToken.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        
        uint256 currentSupply = memeToken.circulatingSupply();
        
        // Calculate OKB return
        uint256 okbReturn = BondingCurveMath.calculateSellReturn(currentSupply, tokenAmount);
        require(okbReturn <= tokenReserves[token], "Insufficient reserves");
        
        // Calculate fee
        uint256 fee = BondingCurveMath.calculateFee(okbReturn, false);
        uint256 okbToUser = okbReturn - fee;
        
        require(okbToUser >= minOkbAmount, "Insufficient output amount");
        
        // Update reserves
        tokenReserves[token] -= okbReturn;
        totalFeesCollected += fee;
        
        // Burn tokens
        memeToken.transferFrom(msg.sender, address(this), tokenAmount);
        memeToken.burn(tokenAmount);
        
        // Update market cap
        uint256 newSupply = currentSupply - tokenAmount;
        uint256 newMarketCap = BondingCurveMath.getCurrentMarketCap(newSupply);
        memeToken.updateMarketCap(newMarketCap);
        
        // Send OKB to user
        (bool success,) = msg.sender.call{value: okbToUser}("");
        require(success, "OKB transfer failed");
        
        // Send fee to fee manager
        if (fee > 0) {
            (bool feeSuccess,) = feeManager.call{value: fee}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        uint256 newPrice = BondingCurveMath.getSpotPrice(newSupply);
        emit TokenSold(token, msg.sender, tokenAmount, okbReturn, fee, newPrice);
    }
    
    /**
     * @dev Get current price for buying tokens
     * @param token Token contract address
     * @param okbAmount Amount of OKB to spend
     * @return tokenAmount Amount of tokens that can be bought
     * @return fee Fee amount
     */
    function getBuyQuote(
        address token,
        uint256 okbAmount
    ) external view returns (uint256 tokenAmount, uint256 fee) {
        require(authorizedTokens[token], "Token not authorized");
        require(!graduatedTokens[token], "Token has graduated");
        
        fee = BondingCurveMath.calculateFee(okbAmount, false);
        uint256 okbForTokens = okbAmount - fee;
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        tokenAmount = BondingCurveMath.calculateTokensForOKB(currentSupply, okbForTokens);
    }
    
    /**
     * @dev Get current price for selling tokens
     * @param token Token contract address
     * @param tokenAmount Amount of tokens to sell
     * @return okbAmount Amount of OKB that will be received
     * @return fee Fee amount
     */
    function getSellQuote(
        address token,
        uint256 tokenAmount
    ) external view returns (uint256 okbAmount, uint256 fee) {
        require(authorizedTokens[token], "Token not authorized");
        require(!graduatedTokens[token], "Token has graduated");
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        
        uint256 grossReturn = BondingCurveMath.calculateSellReturn(currentSupply, tokenAmount);
        fee = BondingCurveMath.calculateFee(grossReturn, false);
        okbAmount = grossReturn - fee;
    }
    
    /**
     * @dev Get token market information
     * @param token Token contract address
     * @return currentSupply Current circulating supply
     * @return marketCap Current market cap
     * @return spotPrice Current spot price
     * @return reserves OKB reserves
     * @return isGraduationReady Whether ready for graduation
     */
    function getTokenMarketInfo(address token) external view returns (
        uint256 currentSupply,
        uint256 marketCap,
        uint256 spotPrice,
        uint256 reserves,
        bool isGraduationReady
    ) {
        MemeToken memeToken = MemeToken(token);
        currentSupply = memeToken.circulatingSupply();
        marketCap = BondingCurveMath.getCurrentMarketCap(currentSupply);
        spotPrice = BondingCurveMath.getSpotPrice(currentSupply);
        reserves = tokenReserves[token];
        isGraduationReady = BondingCurveMath.isGraduationReady(currentSupply);
    }
    
    /**
     * @dev Initiate graduation process
     * @param token Token contract address
     */
    function _initiateGraduation(address token) private {
        graduatedTokens[token] = true;
        
        MemeToken memeToken = MemeToken(token);
        uint256 currentSupply = memeToken.circulatingSupply();
        uint256 finalMarketCap = BondingCurveMath.getCurrentMarketCap(currentSupply);
        
        // Call market graduation contract
        (bool success,) = marketGraduation.call(
            abi.encodeWithSignature("graduateToken(address)", token)
        );
        require(success, "Graduation initiation failed");
        
        emit TokenGraduated(token, finalMarketCap, block.timestamp);
    }
    
    /**
     * @dev Emergency withdraw (owner only)
     * @param token Token address (address(0) for OKB)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient OKB balance");
            (bool success,) = owner().call{value: amount}("");
            require(success, "OKB transfer failed");
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
    }
    
    /**
     * @dev Pause/unpause contract
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }
    
    /**
     * @dev Update fee manager address
     * @param _feeManager New fee manager address
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Invalid fee manager");
        feeManager = _feeManager;
    }
    
    /**
     * @dev Update market graduation address
     * @param _marketGraduation New market graduation address
     */
    function setMarketGraduation(address _marketGraduation) external onlyOwner {
        require(_marketGraduation != address(0), "Invalid market graduation");
        marketGraduation = _marketGraduation;
    }
    
    /**
     * @dev Fallback function to receive OKB
     */
    receive() external payable {}
}