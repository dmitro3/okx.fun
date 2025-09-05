// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IOkieSwap.sol";
import "./libraries/BondingCurveMath.sol";

/**
 * @title OkieIntegration
 * @dev Integration contract for OkieSwap V2 and V3 interactions
 * @notice Provides unified interface for trading graduated tokens on OkieSwap
 */
contract OkieIntegration is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // OkieSwap contract interfaces
    IOkieSwapV2Router public immutable okieRouterV2;
    IOkieSwapV2Factory public immutable okieFactoryV2;
    IOkieSwapV3Factory public immutable okieFactoryV3;
    IOkieSwapV3SmartRouter public immutable okieRouterV3;
    
    address public immutable WOKB;
    address public feeManager;
    
    // Trading statistics
    mapping(address => uint256) public tokenTradingVolume;
    mapping(address => uint256) public totalFees;
    uint256 public totalTradingVolume;
    
    // Pool tracking
    mapping(address => PoolInfo) public tokenPools;
    mapping(address => bool) public isGraduatedToken;
    
    struct PoolInfo {
        address v2Pair;
        address v3Pool;
        uint24 v3FeeTier;
        bool hasV2Liquidity;
        bool hasV3Liquidity;
        uint256 lastUpdated;
    }
    
    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool useV3;
        uint24 v3FeeTier;
        uint256 deadline;
    }
    
    // Events
    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        bool usedV3
    );
    
    event PoolInfoUpdated(
        address indexed token,
        address v2Pair,
        address v3Pool,
        uint24 v3FeeTier
    );
    
    event LiquidityAdded(
        address indexed token,
        address indexed pool,
        uint256 tokenAmount,
        uint256 okbAmount,
        bool isV3
    );
    
    /**
     * @dev Constructor
     * @param _okieRouterV2 OkieSwap V2 Router address
     * @param _okieFactoryV2 OkieSwap V2 Factory address
     * @param _okieFactoryV3 OkieSwap V3 Factory address
     * @param _okieRouterV3 OkieSwap V3 Smart Router address
     * @param _WOKB Wrapped OKB address
     */
    constructor(
        address _okieRouterV2,
        address _okieFactoryV2,
        address _okieFactoryV3,
        address _okieRouterV3,
        address _WOKB
    ) Ownable(msg.sender) ReentrancyGuard() {
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
     * @dev Set fee manager address
     * @param _feeManager Fee manager contract address
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Invalid fee manager");
        feeManager = _feeManager;
    }
    
    /**
     * @dev Register a graduated token and update pool info
     * @param token Token address
     * @param v2Pair V2 pair address (can be address(0))
     * @param v3Pool V3 pool address (can be address(0))
     * @param v3FeeTier V3 fee tier (0 if no V3 pool)
     */
    function registerGraduatedToken(
        address token,
        address v2Pair,
        address v3Pool,
        uint24 v3FeeTier
    ) external onlyOwner {
        require(token != address(0), "Invalid token");
        
        isGraduatedToken[token] = true;
        tokenPools[token] = PoolInfo({
            v2Pair: v2Pair,
            v3Pool: v3Pool,
            v3FeeTier: v3FeeTier,
            hasV2Liquidity: v2Pair != address(0),
            hasV3Liquidity: v3Pool != address(0),
            lastUpdated: block.timestamp
        });
        
        emit PoolInfoUpdated(token, v2Pair, v3Pool, v3FeeTier);
    }
    
    /**
     * @dev Swap tokens using optimal route (V2 or V3)
     * @param params Swap parameters
     */
    function swapTokens(SwapParams calldata params) external payable nonReentrant {
        require(params.deadline >= block.timestamp, "Deadline exceeded");
        require(params.amountIn > 0, "Invalid input amount");
        
        // Determine if this is an OKB swap
        bool isOKBIn = params.tokenIn == address(0);
        bool isOKBOut = params.tokenOut == address(0);
        
        if (isOKBIn) {
            require(msg.value == params.amountIn, "Incorrect OKB amount");
        } else {
            require(msg.value == 0, "Unexpected OKB sent");
            IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        }
        
        uint256 amountOut;
        
        // Use V3 if specified and available, otherwise use V2
        if (params.useV3 && _hasV3Liquidity(params.tokenIn, params.tokenOut, params.v3FeeTier)) {
            amountOut = _swapV3(params, isOKBIn, isOKBOut);
        } else {
            amountOut = _swapV2(params, isOKBIn, isOKBOut);
        }
        
        require(amountOut >= params.amountOutMin, "Insufficient output amount");
        
        // Calculate and collect fees
        uint256 fee = BondingCurveMath.calculateFee(amountOut, true); // Post-graduation fee
        uint256 amountToUser = amountOut - fee;
        
        // Transfer tokens to user
        if (isOKBOut) {
            (bool success,) = msg.sender.call{value: amountToUser}("");
            require(success, "OKB transfer failed");
            
            // Send fee to fee manager
            if (fee > 0 && feeManager != address(0)) {
                (bool feeSuccess,) = feeManager.call{value: fee}("");
                require(feeSuccess, "Fee transfer failed");
            }
        } else {
            IERC20(params.tokenOut).safeTransfer(msg.sender, amountToUser);
            
            // Send fee to fee manager
            if (fee > 0 && feeManager != address(0)) {
                IERC20(params.tokenOut).safeTransfer(feeManager, fee);
            }
        }
        
        // Update statistics
        _updateTradingStats(params.tokenIn, params.tokenOut, params.amountIn, amountOut, fee);
        
        emit SwapExecuted(
            params.tokenIn,
            params.tokenOut,
            msg.sender,
            params.amountIn,
            amountOut,
            fee,
            params.useV3
        );
    }
    
    /**
     * @dev Execute V2 swap
     */
    function _swapV2(
        SwapParams calldata params,
        bool isOKBIn,
        bool isOKBOut
    ) private returns (uint256 amountOut) {
        if (isOKBIn && !isOKBOut) {
            // OKB -> Token
            address[] memory path = new address[](2);
            path[0] = WOKB;
            path[1] = params.tokenOut;
            
            uint[] memory amounts = okieRouterV2.swapExactOKBForTokens{
                value: params.amountIn
            }(
                0, // We'll check slippage after
                path,
                address(this),
                params.deadline
            );
            
            amountOut = amounts[amounts.length - 1];
            
        } else if (!isOKBIn && isOKBOut) {
            // Token -> OKB
            IERC20(params.tokenIn).approve(address(okieRouterV2), params.amountIn);
            
            address[] memory path = new address[](2);
            path[0] = params.tokenIn;
            path[1] = WOKB;
            
            uint[] memory amounts = okieRouterV2.swapExactTokensForOKB(
                params.amountIn,
                0, // We'll check slippage after
                path,
                address(this),
                params.deadline
            );
            
            amountOut = amounts[amounts.length - 1];
            
        } else if (!isOKBIn && !isOKBOut) {
            // Token -> Token (via WOKB)
            IERC20(params.tokenIn).approve(address(okieRouterV2), params.amountIn);
            
            address[] memory path = new address[](3);
            path[0] = params.tokenIn;
            path[1] = WOKB;
            path[2] = params.tokenOut;
            
            uint[] memory amounts = okieRouterV2.swapExactTokensForTokens(
                params.amountIn,
                0, // We'll check slippage after
                path,
                address(this),
                params.deadline
            );
            
            amountOut = amounts[amounts.length - 1];
        } else {
            revert("Invalid swap: OKB to OKB");
        }
    }
    
    /**
     * @dev Execute V3 swap
     */
    function _swapV3(
        SwapParams calldata params,
        bool isOKBIn,
        bool isOKBOut
    ) private returns (uint256 amountOut) {
        if (isOKBIn && !isOKBOut) {
            // OKB -> Token
            IOkieSwapV3SmartRouter.ExactInputSingleParams memory swapParams = 
                IOkieSwapV3SmartRouter.ExactInputSingleParams({
                    tokenIn: WOKB,
                    tokenOut: params.tokenOut,
                    fee: params.v3FeeTier,
                    recipient: address(this),
                    deadline: params.deadline,
                    amountIn: params.amountIn,
                    amountOutMinimum: 0, // We'll check slippage after
                    sqrtPriceLimitX96: 0
                });
            
            amountOut = okieRouterV3.exactInputSingle{value: params.amountIn}(swapParams);
            
        } else if (!isOKBIn && isOKBOut) {
            // Token -> OKB
            IERC20(params.tokenIn).approve(address(okieRouterV3), params.amountIn);
            
            IOkieSwapV3SmartRouter.ExactInputSingleParams memory swapParams = 
                IOkieSwapV3SmartRouter.ExactInputSingleParams({
                    tokenIn: params.tokenIn,
                    tokenOut: WOKB,
                    fee: params.v3FeeTier,
                    recipient: address(this),
                    deadline: params.deadline,
                    amountIn: params.amountIn,
                    amountOutMinimum: 0, // We'll check slippage after
                    sqrtPriceLimitX96: 0
                });
            
            amountOut = okieRouterV3.exactInputSingle(swapParams);
            
        } else {
            revert("V3 token-to-token swaps not implemented");
        }
    }
    
    /**
     * @dev Check if V3 liquidity exists for a pair
     */
    function _hasV3Liquidity(
        address tokenIn,
        address tokenOut,
        uint24 feeTier
    ) private view returns (bool) {
        address tokenA = tokenIn == address(0) ? WOKB : tokenIn;
        address tokenB = tokenOut == address(0) ? WOKB : tokenOut;
        
        if (tokenA == tokenB) return false;
        
        address pool = okieFactoryV3.getPool(tokenA, tokenB, feeTier);
        return pool != address(0);
    }
    
    /**
     * @dev Update trading statistics
     */
    function _updateTradingStats(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee
    ) private {
        // Update token-specific volume
        if (tokenIn != address(0) && isGraduatedToken[tokenIn]) {
            tokenTradingVolume[tokenIn] += amountIn;
            totalFees[tokenIn] += fee;
        }
        if (tokenOut != address(0) && isGraduatedToken[tokenOut]) {
            tokenTradingVolume[tokenOut] += amountOut;
        }
        
        // Update total volume
        totalTradingVolume += amountIn;
    }
    
    /**
     * @dev Get swap quote for tokens
     * @param tokenIn Input token address (address(0) for OKB)
     * @param tokenOut Output token address (address(0) for OKB)
     * @param amountIn Input amount
     * @param useV3 Whether to use V3
     * @param v3FeeTier V3 fee tier
     * @return amountOut Expected output amount
     * @return fee Expected fee amount
     */
    function getSwapQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        bool useV3,
        uint24 v3FeeTier
    ) external view returns (uint256 amountOut, uint256 fee) {
        require(amountIn > 0, "Invalid input amount");
        
        if (useV3 && _hasV3Liquidity(tokenIn, tokenOut, v3FeeTier)) {
            // V3 quote logic would go here
            // For simplicity, we'll use V2 logic
            amountOut = _getV2Quote(tokenIn, tokenOut, amountIn);
        } else {
            amountOut = _getV2Quote(tokenIn, tokenOut, amountIn);
        }
        
        fee = BondingCurveMath.calculateFee(amountOut, true);
    }
    
    /**
     * @dev Get V2 swap quote
     */
    function _getV2Quote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) private view returns (uint256 amountOut) {
        address[] memory path;
        
        if (tokenIn == address(0) && tokenOut != address(0)) {
            // OKB -> Token
            path = new address[](2);
            path[0] = WOKB;
            path[1] = tokenOut;
        } else if (tokenIn != address(0) && tokenOut == address(0)) {
            // Token -> OKB
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = WOKB;
        } else if (tokenIn != address(0) && tokenOut != address(0)) {
            // Token -> Token
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = WOKB;
            path[2] = tokenOut;
        } else {
            revert("Invalid swap: OKB to OKB");
        }
        
        try okieRouterV2.getAmountsOut(amountIn, path) returns (uint[] memory amounts) {
            amountOut = amounts[amounts.length - 1];
        } catch {
            amountOut = 0;
        }
    }
    
    /**
     * @dev Get token pool information
     * @param token Token address
     * @return poolInfo Pool information
     */
    function getTokenPoolInfo(address token) external view returns (PoolInfo memory poolInfo) {
        return tokenPools[token];
    }
    
    /**
     * @dev Get trading statistics for a token
     * @param token Token address
     * @return volume Total trading volume
     * @return fees Total fees collected
     */
    function getTradingStats(address token) external view returns (uint256 volume, uint256 fees) {
        return (tokenTradingVolume[token], totalFees[token]);
    }
    
    /**
     * @dev Emergency function to recover tokens
     * @param token Token address (address(0) for OKB)
     * @param amount Amount to recover
     */
    function emergencyRecover(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient OKB balance");
            (bool success,) = owner().call{value: amount}("");
            require(success, "OKB transfer failed");
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
    }
    
    /**
     * @dev Fallback function to receive OKB
     */
    receive() external payable {
        // Allow contract to receive OKB for swaps
    }
}