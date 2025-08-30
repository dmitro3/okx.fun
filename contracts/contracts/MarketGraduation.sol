// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/BondingCurveMath.sol";
import "./MemeToken.sol";
import "./interfaces/IOkieSwap.sol";

/**
 * @title MarketGraduation
 * @dev Handles token graduation from bonding curve to DEX trading
 * @notice Manages the transition of tokens to OkieSwap liquidity pools
 */
contract MarketGraduation is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // OkieSwap contract addresses
    IOkieSwapV2Router public immutable okieRouterV2;
    IOkieSwapV2Factory public immutable okieFactoryV2;
    IOkieSwapV3Factory public immutable okieFactoryV3;
    IOkieSwapV3SmartRouter public immutable okieRouterV3;
    
    address public immutable WOKB;
    address public bondingCurve;
    address public feeManager;
    
    // Graduation parameters
    uint256 public constant LIQUIDITY_OKB = 100 ether; // 100 OKB for liquidity
    uint256 public constant LIQUIDITY_TOKEN_PERCENTAGE = 2000; // 20% in basis points
    uint24 public constant V3_FEE_TIER = 3000; // 0.3% fee tier for V3
    
    // Graduated tokens tracking
    mapping(address => GraduationInfo) public graduatedTokens;
    mapping(address => bool) public isGraduated;
    address[] public allGraduatedTokens;
    
    struct GraduationInfo {
        address token;
        address liquidityPool;
        uint256 graduatedAt;
        uint256 finalMarketCap;
        uint256 liquidityTokens;
        uint256 liquidityOKB;
        bool useV3;
        uint24 v3FeeTier;
    }
    
    // Events
    event TokenGraduated(
        address indexed token,
        address indexed liquidityPool,
        uint256 liquidityTokens,
        uint256 liquidityOKB,
        uint256 finalMarketCap,
        bool useV3,
        uint256 timestamp
    );
    
    event LiquidityAdded(
        address indexed token,
        address indexed pool,
        uint256 tokenAmount,
        uint256 okbAmount
    );
    
    event GraduationFailed(
        address indexed token,
        string reason,
        uint256 timestamp
    );
    
    /**
     * @dev Constructor
     * @param _okieRouterV2 OkieSwap V2 Router address
     * @param _okieFactoryV2 OkieSwap V2 Factory address
     * @param _okieFactoryV3 OkieSwap V3 Factory address
     * @param _okieRouterV3 OkieSwap V3 Smart Router address
     * @param _WOKB Wrapped OKB token address
     */
    constructor(
        address _okieRouterV2,
        address _okieFactoryV2,
        address _okieFactoryV3,
        address _okieRouterV3,
        address _WOKB
    ) {
        require(_okieRouterV2 != address(0), "Invalid V2 router");
        require(_okieFactoryV2 != address(0), "Invalid V2 factory");
        require(_okieFactoryV3 != address(0), "Invalid V3 factory");
        require(_okieRouterV3 != address(0), "Invalid V3 router");
        require(_WOKB != address(0), "Invalid WOKB");
        
        okieRouterV2 = IOkieSwapV2Router(_okieRouterV2);
        okieFactoryV2 = IOkieSwapV2Factory(_okieFactoryV2);
        okieFactoryV3 = IOkieSwapV3Factory(_okieFactoryV3);
        okieRouterV3 = IOkieSwapV3SmartRouter(_okieRouterV3);
        WOKB = _WOKB;
    }
    
    /**
     * @dev Set bonding curve address (owner only)
     * @param _bondingCurve Bonding curve contract address
     */
    function setBondingCurve(address _bondingCurve) external onlyOwner {
        require(_bondingCurve != address(0), "Invalid bonding curve");
        bondingCurve = _bondingCurve;
    }
    
    /**
     * @dev Set fee manager address (owner only)
     * @param _feeManager Fee manager contract address
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Invalid fee manager");
        feeManager = _feeManager;
    }
    
    /**
     * @dev Graduate a token to DEX trading
     * @param token Token address to graduate
     */
    function graduateToken(address token) external nonReentrant {
        require(msg.sender == bondingCurve, "Only bonding curve can graduate");
        require(!isGraduated[token], "Token already graduated");
        
        MemeToken memeToken = MemeToken(token);
        require(memeToken.isReadyForGraduation(), "Token not ready for graduation");
        
        // Calculate graduation parameters
        uint256 tokenSupply = memeToken.totalSupply();
        uint256 liquidityTokens = tokenSupply * LIQUIDITY_TOKEN_PERCENTAGE / 10000;
        uint256 finalMarketCap = memeToken.marketCap();
        
        // Determine whether to use V2 or V3 based on market cap
        bool useV3 = finalMarketCap >= 100000 ether; // Use V3 for larger market caps
        
        address liquidityPool;
        if (useV3) {
            liquidityPool = _graduateToV3(token, liquidityTokens);
        } else {
            liquidityPool = _graduateToV2(token, liquidityTokens);
        }
        
        if (liquidityPool != address(0)) {
            // Mark as graduated
            isGraduated[token] = true;
            memeToken.graduate(liquidityPool);
            
            // Store graduation info
            graduatedTokens[token] = GraduationInfo({
                token: token,
                liquidityPool: liquidityPool,
                graduatedAt: block.timestamp,
                finalMarketCap: finalMarketCap,
                liquidityTokens: liquidityTokens,
                liquidityOKB: LIQUIDITY_OKB,
                useV3: useV3,
                v3FeeTier: useV3 ? V3_FEE_TIER : 0
            });
            
            allGraduatedTokens.push(token);
            
            emit TokenGraduated(
                token,
                liquidityPool,
                liquidityTokens,
                LIQUIDITY_OKB,
                finalMarketCap,
                useV3,
                block.timestamp
            );
        } else {
            emit GraduationFailed(token, "Liquidity pool creation failed", block.timestamp);
            revert("Graduation failed");
        }
    }
    
    /**
     * @dev Graduate token to OkieSwap V2
     * @param token Token address
     * @param liquidityTokens Amount of tokens for liquidity
     * @return pair V2 pair address
     */
    function _graduateToV2(address token, uint256 liquidityTokens) private returns (address pair) {
        // Check if pair exists, create if not
        pair = okieFactoryV2.getPair(token, WOKB);
        if (pair == address(0)) {
            pair = okieFactoryV2.createPair(token, WOKB);
        }
        
        // Approve tokens for router
        IERC20(token).safeApprove(address(okieRouterV2), liquidityTokens);
        
        // Add liquidity
        try okieRouterV2.addLiquidityOKB{
            value: LIQUIDITY_OKB
        }(
            token,
            liquidityTokens,
            liquidityTokens * 95 / 100, // 5% slippage tolerance
            LIQUIDITY_OKB * 95 / 100,   // 5% slippage tolerance
            address(this), // LP tokens to this contract
            block.timestamp + 300 // 5 minute deadline
        ) returns (uint256 amountToken, uint256 amountOKB, uint256 liquidity) {
            emit LiquidityAdded(token, pair, amountToken, amountOKB);
            
            // Send any excess tokens back to bonding curve
            uint256 excessTokens = liquidityTokens - amountToken;
            if (excessTokens > 0) {
                IERC20(token).safeTransfer(bondingCurve, excessTokens);
            }
            
            // Refund excess OKB to bonding curve
            uint256 excessOKB = LIQUIDITY_OKB - amountOKB;
            if (excessOKB > 0) {
                (bool success,) = bondingCurve.call{value: excessOKB}("");
                require(success, "OKB refund failed");
            }
            
        } catch Error(string memory reason) {
            emit GraduationFailed(token, reason, block.timestamp);
            return address(0);
        } catch {
            emit GraduationFailed(token, "Unknown error in V2 liquidity", block.timestamp);
            return address(0);
        }
    }
    
    /**
     * @dev Graduate token to OkieSwap V3
     * @param token Token address
     * @param liquidityTokens Amount of tokens for liquidity
     * @return pool V3 pool address
     */
    function _graduateToV3(address token, uint256 liquidityTokens) private returns (address pool) {
        // Check if pool exists, create if not
        pool = okieFactoryV3.getPool(token, WOKB, V3_FEE_TIER);
        if (pool == address(0)) {
            pool = okieFactoryV3.createPool(token, WOKB, V3_FEE_TIER);
        }
        
        // For V3, we would need to implement position management
        // This is a simplified version - in production, you'd want to:
        // 1. Initialize the pool if not initialized
        // 2. Calculate appropriate tick ranges
        // 3. Use the PositionManager for minting positions
        
        // For now, fall back to V2 for simplicity
        // In a full implementation, you'd handle V3 liquidity provision here
        return _graduateToV2(token, liquidityTokens);
    }
    
    /**
     * @dev Get graduation info for a token
     * @param token Token address
     * @return info Graduation information
     */
    function getGraduationInfo(address token) external view returns (GraduationInfo memory info) {
        require(isGraduated[token], "Token not graduated");
        return graduatedTokens[token];
    }
    
    /**
     * @dev Get all graduated tokens (paginated)
     * @param offset Starting index
     * @param limit Maximum number of results
     * @return tokens Array of graduated token addresses
     * @return total Total number of graduated tokens
     */
    function getAllGraduatedTokens(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory tokens, uint256 total) {
        total = allGraduatedTokens.length;
        
        if (offset >= total) {
            return (new address[](0), total);
        }
        
        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }
        
        tokens = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            tokens[i - offset] = allGraduatedTokens[i];
        }
    }
    
    /**
     * @dev Check if a token is ready for graduation
     * @param token Token address
     * @return ready Whether the token is ready
     * @return marketCap Current market cap
     */
    function isTokenReadyForGraduation(
        address token
    ) external view returns (bool ready, uint256 marketCap) {
        MemeToken memeToken = MemeToken(token);
        marketCap = memeToken.marketCap();
        ready = marketCap >= BondingCurveMath.GRADUATION_MARKET_CAP;
    }
    
    /**
     * @dev Emergency function to recover stuck tokens or OKB
     * @param tokenAddress Token address (address(0) for OKB)
     * @param amount Amount to recover
     */
    function emergencyRecover(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount, "Insufficient OKB balance");
            (bool success,) = owner().call{value: amount}("");
            require(success, "OKB transfer failed");
        } else {
            IERC20(tokenAddress).safeTransfer(owner(), amount);
        }
    }
    
    /**
     * @dev Get graduation statistics
     * @return stats Graduation statistics
     */
    function getGraduationStats() external view returns (
        uint256 totalGraduated,
        uint256 totalLiquidityOKB,
        uint256 v2Graduations,
        uint256 v3Graduations
    ) {
        totalGraduated = allGraduatedTokens.length;
        totalLiquidityOKB = totalGraduated * LIQUIDITY_OKB;
        
        // Count V2 vs V3 graduations
        for (uint256 i = 0; i < totalGraduated; i++) {
            if (graduatedTokens[allGraduatedTokens[i]].useV3) {
                v3Graduations++;
            } else {
                v2Graduations++;
            }
        }
    }
    
    /**
     * @dev Fallback function to receive OKB
     */
    receive() external payable {
        // Allow contract to receive OKB for graduation liquidity
    }
}