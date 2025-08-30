// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title BondingCurveMath
 * @dev Mathematical library for bonding curve calculations
 * @notice Implements linear bonding curve: price = slope * supply + base_price
 */
library BondingCurveMath {
    using Math for uint256;

    // Constants for OKX Finance bonding curve
    uint256 public constant GRADUATION_MARKET_CAP = 50000 ether; // $50,000 in wei
    uint256 public constant INITIAL_MARKET_CAP = 3000 ether; // $3,000 in wei
    uint256 public constant GRADUATION_OKB_AMOUNT = 500 ether; // 500 OKB
    uint256 public constant INITIAL_SUPPLY = 1000000 ether; // 1M tokens
    
    // Fee constants
    uint256 public constant BONDING_FEE_BASIS_POINTS = 100; // 1%
    uint256 public constant POST_GRADUATION_FEE_BASIS_POINTS = 25; // 0.25%
    uint256 public constant BASIS_POINTS = 10000;

    /**
     * @dev Calculate the price for buying tokens using linear bonding curve
     * @param currentSupply Current circulating supply
     * @param tokenAmount Amount of tokens to buy
     * @return price Price in OKB for the token amount
     */
    function calculateBuyPrice(
        uint256 currentSupply,
        uint256 tokenAmount
    ) internal pure returns (uint256 price) {
        require(tokenAmount > 0, "Token amount must be > 0");
        
        // Linear bonding curve: price increases linearly with supply
        // Area under the curve from currentSupply to (currentSupply + tokenAmount)
        uint256 startPrice = getSpotPrice(currentSupply);
        uint256 endPrice = getSpotPrice(currentSupply + tokenAmount);
        
        // Average price * quantity
        price = (startPrice + endPrice) * tokenAmount / 2;
    }

    /**
     * @dev Calculate the return for selling tokens
     * @param currentSupply Current circulating supply
     * @param tokenAmount Amount of tokens to sell
     * @return return_ Return in OKB for the token amount
     */
    function calculateSellReturn(
        uint256 currentSupply,
        uint256 tokenAmount
    ) internal pure returns (uint256 return_) {
        require(tokenAmount > 0, "Token amount must be > 0");
        require(currentSupply >= tokenAmount, "Insufficient supply");
        
        uint256 startPrice = getSpotPrice(currentSupply - tokenAmount);
        uint256 endPrice = getSpotPrice(currentSupply);
        
        // Average price * quantity
        return_ = (startPrice + endPrice) * tokenAmount / 2;
    }

    /**
     * @dev Get the current spot price for a given supply level
     * @param currentSupply Current circulating supply
     * @return price Current spot price in OKB per token
     */
    function getSpotPrice(uint256 currentSupply) internal pure returns (uint256 price) {
        // Linear curve: price = (market_cap_range / supply_range) * supply + initial_price
        uint256 marketCapRange = GRADUATION_MARKET_CAP - INITIAL_MARKET_CAP;
        uint256 supplyRange = INITIAL_SUPPLY;
        
        // Calculate slope: market cap increase per token
        uint256 slope = marketCapRange * 1e18 / supplyRange;
        
        // Base price at zero supply (theoretical)
        uint256 basePrice = INITIAL_MARKET_CAP * 1e18 / INITIAL_SUPPLY;
        
        price = (slope * currentSupply / 1e18) + basePrice;
    }

    /**
     * @dev Calculate current market cap based on supply
     * @param currentSupply Current circulating supply
     * @return marketCap Current market capitalization in OKB
     */
    function getCurrentMarketCap(uint256 currentSupply) internal pure returns (uint256 marketCap) {
        if (currentSupply == 0) {
            return 0;
        }
        
        uint256 spotPrice = getSpotPrice(currentSupply);
        marketCap = spotPrice * currentSupply / 1e18;
    }

    /**
     * @dev Check if token is ready for graduation to DEX
     * @param currentSupply Current circulating supply
     * @return isReady True if ready for graduation
     */
    function isGraduationReady(uint256 currentSupply) internal pure returns (bool isReady) {
        uint256 marketCap = getCurrentMarketCap(currentSupply);
        isReady = marketCap >= GRADUATION_MARKET_CAP;
    }

    /**
     * @dev Calculate fees for a transaction
     * @param amount Transaction amount
     * @param isPostGraduation Whether the token has graduated
     * @return fee Fee amount
     */
    function calculateFee(
        uint256 amount,
        bool isPostGraduation
    ) internal pure returns (uint256 fee) {
        uint256 feeRate = isPostGraduation ? POST_GRADUATION_FEE_BASIS_POINTS : BONDING_FEE_BASIS_POINTS;
        fee = amount * feeRate / BASIS_POINTS;
    }

    /**
     * @dev Calculate amount of tokens that can be bought with OKB amount
     * @param currentSupply Current circulating supply
     * @param okbAmount Amount of OKB to spend
     * @return tokenAmount Amount of tokens that can be bought
     */
    function calculateTokensForOKB(
        uint256 currentSupply,
        uint256 okbAmount
    ) internal pure returns (uint256 tokenAmount) {
        require(okbAmount > 0, "OKB amount must be > 0");
        
        // Binary search to find token amount
        uint256 low = 0;
        uint256 high = INITIAL_SUPPLY - currentSupply;
        uint256 precision = 1e12; // Precision for binary search
        
        while (high - low > precision && high > 0) {
            uint256 mid = (low + high) / 2;
            uint256 cost = calculateBuyPrice(currentSupply, mid);
            
            if (cost <= okbAmount) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }
        
        tokenAmount = low;
    }

    /**
     * @dev Calculate graduation parameters
     * @return liquidityOKB Amount of OKB for liquidity (100 OKB)
     * @return tokenPercentage Percentage of tokens for liquidity (20%)
     */
    function getGraduationParams() internal pure returns (uint256 liquidityOKB, uint256 tokenPercentage) {
        liquidityOKB = 100 ether; // 100 OKB
        tokenPercentage = 2000; // 20% in basis points
    }
}