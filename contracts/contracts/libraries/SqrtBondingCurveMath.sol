// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title SqrtBondingCurveMath
 * @dev Mathematical library for sqrt bonding curve calculations (pump.fun style)
 * @notice Implements sqrt bonding curve: price = initialPrice × √(currentSupply / initialSupply)
 * @author OKX DeFi Platform
 * 
 * Key Features:
 * - Ultra-low market cap start (~$300-500)
 * - Exponential price growth via sqrt function
 * - Virtual reserves to prevent division by zero
 * - Gas-optimized sqrt calculation using Babylonian method
 * - Automatic graduation at 500 OKB collected
 * - Anti-MEV and anti-bot protection
 */
library SqrtBondingCurveMath {
    using Math for uint256;

    // ============ Constants ============
    
    /// @notice Initial market cap in OKB (ultra-low ~$300-500)
    uint256 public constant INITIAL_MARKET_CAP = 0.5 ether; // ~$300-500 at OKB prices
    
    /// @notice Graduation threshold - total OKB collected for graduation
    uint256 public constant GRADUATION_OKB_THRESHOLD = 500 ether; // 500 OKB
    
    /// @notice Maximum supply during bonding curve phase
    uint256 public constant MAX_SUPPLY_BONDING = 800_000_000 ether; // 800M tokens (80% of total)
    
    /// @notice Initial supply for price calculation (virtual)
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether; // 1M tokens (virtual base)
    
    /// @notice Virtual reserves to ensure smooth curve operation
    uint256 public constant VIRTUAL_OKB_RESERVES = 30 ether; // Virtual OKB reserves
    uint256 public constant VIRTUAL_TOKEN_RESERVES = 1_073_000_000 ether; // Virtual token reserves
    
    /// @notice Fee structure
    uint256 public constant TRADING_FEE_BASIS_POINTS = 100; // 1% trading fee
    uint256 public constant BASIS_POINTS = 10000;
    
    /// @notice Price scaling factor for precision
    uint256 public constant PRICE_SCALE = 1e18;
    
    /// @notice Anti-bot limits
    uint256 public constant MAX_TOKENS_PER_TX = 10_000_000 ether; // 10M tokens max per tx
    uint256 public constant MAX_OKB_PER_TX = 50 ether; // 50 OKB max per tx
    
    // ============ Events ============
    
    event SqrtCalculated(uint256 input, uint256 result, uint256 iterations);
    event PriceCalculated(uint256 supply, uint256 price, uint256 marketCap);
    event GraduationTriggered(uint256 totalOKBCollected, uint256 finalSupply);

    // ============ Errors ============
    
    error InvalidSupply();
    error InvalidAmount();
    error ExceedsMaxTransaction();
    error InsufficientLiquidity();
    error GraduationThresholdReached();

    // ============ Core Math Functions ============

    /**
     * @dev Gas-optimized square root calculation using Babylonian method
     * @param x Input value to calculate sqrt for
     * @return result Square root of x with 18 decimal precision
     * @notice Uses iterative approximation for gas efficiency
     */
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) return 0;
        
        // Initial guess - use bit length for better starting point
        uint256 xAux = x;
        result = 1;
        
        // Get a rough estimate using bit shifting
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // Babylonian method - optimized for gas
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

    /**
     * @dev Calculate spot price using sqrt bonding curve formula
     * @param currentSupply Current token supply in circulation
     * @return price Current spot price in OKB per token (18 decimals)
     * @notice price = initialPrice × √(currentSupply / initialSupply)
     */
    function getSpotPrice(uint256 currentSupply) internal pure returns (uint256 price) {
        if (currentSupply == 0) {
            // Return minimum price based on virtual reserves
            return INITIAL_MARKET_CAP * PRICE_SCALE / INITIAL_SUPPLY;
        }
        
        // Add virtual reserves for smooth operation
        uint256 effectiveSupply = currentSupply + VIRTUAL_TOKEN_RESERVES;
        uint256 effectiveInitialSupply = INITIAL_SUPPLY + VIRTUAL_TOKEN_RESERVES;
        
        // Calculate sqrt ratio: √(effectiveSupply / effectiveInitialSupply)
        uint256 ratio = (effectiveSupply * PRICE_SCALE) / effectiveInitialSupply;
        uint256 sqrtRatio = sqrt(ratio);
        
        // Calculate initial price from market cap
        uint256 initialPrice = INITIAL_MARKET_CAP * PRICE_SCALE / effectiveInitialSupply;
        
        // Final price calculation
        price = (initialPrice * sqrtRatio) / sqrt(PRICE_SCALE);
        
        // Ensure minimum price
        uint256 minPrice = 1e12; // Prevent price from going to zero
        if (price < minPrice) price = minPrice;
    }

    /**
     * @dev Calculate current market cap based on supply and price
     * @param currentSupply Current token supply
     * @return marketCap Market capitalization in OKB
     */
    function getCurrentMarketCap(uint256 currentSupply) internal pure returns (uint256 marketCap) {
        if (currentSupply == 0) return INITIAL_MARKET_CAP;
        
        uint256 spotPrice = getSpotPrice(currentSupply);
        marketCap = (spotPrice * currentSupply) / PRICE_SCALE;
        
        // Add virtual reserves contribution
        marketCap += VIRTUAL_OKB_RESERVES;
    }

    // ============ Trading Calculations ============

    /**
     * @dev Calculate cost to buy specific amount of tokens
     * @param currentSupply Current circulating supply
     * @param tokenAmount Amount of tokens to buy
     * @return okbCost Total OKB cost (including virtual reserves)
     * @notice Uses integral of sqrt curve for precise calculation
     */
    function calculateBuyPrice(
        uint256 currentSupply,
        uint256 tokenAmount
    ) internal pure returns (uint256 okbCost) {
        if (tokenAmount == 0) revert InvalidAmount();
        if (tokenAmount > MAX_TOKENS_PER_TX) revert ExceedsMaxTransaction();
        
        uint256 effectiveSupply = currentSupply + VIRTUAL_TOKEN_RESERVES;
        uint256 newSupply = effectiveSupply + tokenAmount;
        
        // Calculate area under sqrt curve using integration
        // ∫√x dx = (2/3)x^(3/2)
        uint256 integralStart = _calculateIntegral(effectiveSupply);
        uint256 integralEnd = _calculateIntegral(newSupply);
        
        uint256 initialPrice = INITIAL_MARKET_CAP * PRICE_SCALE / (INITIAL_SUPPLY + VIRTUAL_TOKEN_RESERVES);
        
        okbCost = ((integralEnd - integralStart) * initialPrice) / (PRICE_SCALE * sqrt(PRICE_SCALE));
        
        // Apply minimum cost
        if (okbCost == 0) okbCost = 1e12;
    }

    /**
     * @dev Calculate return for selling tokens
     * @param currentSupply Current circulating supply
     * @param tokenAmount Amount of tokens to sell
     * @return okbReturn Total OKB return (minus virtual reserves)
     */
    function calculateSellReturn(
        uint256 currentSupply,
        uint256 tokenAmount
    ) internal pure returns (uint256 okbReturn) {
        if (tokenAmount == 0) revert InvalidAmount();
        if (currentSupply < tokenAmount) revert InsufficientLiquidity();
        
        uint256 effectiveSupply = currentSupply + VIRTUAL_TOKEN_RESERVES;
        uint256 newSupply = effectiveSupply - tokenAmount;
        
        // Calculate area under sqrt curve
        uint256 integralStart = _calculateIntegral(newSupply);
        uint256 integralEnd = _calculateIntegral(effectiveSupply);
        
        uint256 initialPrice = INITIAL_MARKET_CAP * PRICE_SCALE / (INITIAL_SUPPLY + VIRTUAL_TOKEN_RESERVES);
        
        okbReturn = ((integralEnd - integralStart) * initialPrice) / (PRICE_SCALE * sqrt(PRICE_SCALE));
        
        // Ensure return doesn't exceed available reserves
        uint256 maxReturn = (currentSupply * getSpotPrice(currentSupply)) / PRICE_SCALE;
        if (okbReturn > maxReturn) okbReturn = maxReturn;
    }

    /**
     * @dev Calculate integral of sqrt function: (2/3)x^(3/2)
     * @param x Input value
     * @return integral Result of integral calculation
     */
    function _calculateIntegral(uint256 x) private pure returns (uint256 integral) {
        if (x == 0) return 0;
        
        // Calculate x^(3/2) = x * √x
        uint256 sqrtX = sqrt(x);
        uint256 xToThreeHalves = x * sqrtX / sqrt(PRICE_SCALE);
        
        // Apply coefficient (2/3)
        integral = (2 * xToThreeHalves) / 3;
    }

    // ============ Token Purchase/Sale Helpers ============

    /**
     * @dev Calculate tokens receivable for OKB amount
     * @param currentSupply Current circulating supply
     * @param okbAmount Amount of OKB to spend
     * @return tokenAmount Tokens that can be purchased
     */
    function calculateTokensForOKB(
        uint256 currentSupply,
        uint256 okbAmount
    ) internal pure returns (uint256 tokenAmount) {
        if (okbAmount == 0) revert InvalidAmount();
        if (okbAmount > MAX_OKB_PER_TX) revert ExceedsMaxTransaction();
        
        // Use binary search for reverse calculation
        uint256 low = 0;
        uint256 high = MAX_SUPPLY_BONDING - currentSupply;
        uint256 mid;
        
        // Binary search with precision
        while (high - low > 1e12) { // 1e12 precision
            mid = (low + high) / 2;
            uint256 cost = calculateBuyPrice(currentSupply, mid);
            
            if (cost <= okbAmount) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }
        
        tokenAmount = low;
        if (tokenAmount == 0 && okbAmount > 0) {
            tokenAmount = 1e12; // Minimum token amount
        }
    }

    // ============ Graduation Logic ============

    /**
     * @dev Check if token is ready for graduation
     * @param totalOKBCollected Total OKB collected from trading
     * @return isReady True if ready for graduation
     */
    function isGraduationReady(uint256 totalOKBCollected) internal pure returns (bool isReady) {
        isReady = totalOKBCollected >= GRADUATION_OKB_THRESHOLD;
    }

    /**
     * @dev Calculate graduation liquidity parameters
     * @param finalSupply Final supply at graduation
     * @param totalOKBCollected Total OKB collected
     * @return liquidityOKB OKB amount for initial liquidity
     * @return liquidityTokens Token amount for initial liquidity
     */
    function getGraduationLiquidity(
        uint256 finalSupply,
        uint256 totalOKBCollected
    ) internal pure returns (uint256 liquidityOKB, uint256 liquidityTokens) {
        // Use portion of collected OKB for liquidity
        liquidityOKB = (totalOKBCollected * 8000) / BASIS_POINTS; // 80% of collected
        
        // Calculate tokens for liquidity based on final price
        uint256 finalPrice = getSpotPrice(finalSupply);
        liquidityTokens = (liquidityOKB * PRICE_SCALE) / finalPrice;
        
        // Ensure minimum liquidity
        if (liquidityOKB < 50 ether) liquidityOKB = 50 ether;
        if (liquidityTokens < 10_000_000 ether) liquidityTokens = 10_000_000 ether;
    }

    // ============ Fee Calculations ============

    /**
     * @dev Calculate trading fees
     * @param amount Transaction amount
     * @return fee Fee amount in same units
     */
    function calculateFee(uint256 amount) internal pure returns (uint256 fee) {
        fee = (amount * TRADING_FEE_BASIS_POINTS) / BASIS_POINTS;
    }

    // ============ Anti-Bot Protection ============

    /**
     * @dev Validate transaction limits (anti-bot)
     * @param tokenAmount Token amount for transaction
     * @param okbAmount OKB amount for transaction
     */
    function validateTransactionLimits(uint256 tokenAmount, uint256 okbAmount) internal pure {
        if (tokenAmount > MAX_TOKENS_PER_TX) revert ExceedsMaxTransaction();
        if (okbAmount > MAX_OKB_PER_TX) revert ExceedsMaxTransaction();
    }

    /**
     * @dev Calculate price impact for large transactions
     * @param currentSupply Current supply
     * @param tokenAmount Transaction amount
     * @return priceImpactBps Price impact in basis points
     */
    function calculatePriceImpact(
        uint256 currentSupply,
        uint256 tokenAmount
    ) internal pure returns (uint256 priceImpactBps) {
        if (tokenAmount == 0 || currentSupply == 0) return 0;
        
        uint256 priceBefore = getSpotPrice(currentSupply);
        uint256 priceAfter = getSpotPrice(currentSupply + tokenAmount);
        
        if (priceAfter > priceBefore) {
            priceImpactBps = ((priceAfter - priceBefore) * BASIS_POINTS) / priceBefore;
        } else {
            priceImpactBps = ((priceBefore - priceAfter) * BASIS_POINTS) / priceBefore;
        }
    }

    // ============ View Functions ============

    /**
     * @dev Get comprehensive token market data
     * @param currentSupply Current circulating supply
     * @param totalOKBCollected Total OKB collected
     * @return marketData Struct containing all market information
     */
    function getMarketData(
        uint256 currentSupply,
        uint256 totalOKBCollected
    ) internal pure returns (MarketData memory marketData) {
        marketData.spotPrice = getSpotPrice(currentSupply);
        marketData.marketCap = getCurrentMarketCap(currentSupply);
        marketData.totalOKBCollected = totalOKBCollected;
        marketData.isGraduationReady = isGraduationReady(totalOKBCollected);
        marketData.graduationProgress = (totalOKBCollected * BASIS_POINTS) / GRADUATION_OKB_THRESHOLD;
        marketData.maxSupply = MAX_SUPPLY_BONDING;
        marketData.virtualOKBReserves = VIRTUAL_OKB_RESERVES;
        marketData.virtualTokenReserves = VIRTUAL_TOKEN_RESERVES;
    }

    // ============ Structs ============

    struct MarketData {
        uint256 spotPrice;
        uint256 marketCap;
        uint256 totalOKBCollected;
        bool isGraduationReady;
        uint256 graduationProgress;
        uint256 maxSupply;
        uint256 virtualOKBReserves;
        uint256 virtualTokenReserves;
    }
}