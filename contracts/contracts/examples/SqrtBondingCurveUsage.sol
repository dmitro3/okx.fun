// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../BondingCurveV2.sol";
import "../MemeToken.sol";
import "../interfaces/IBondingCurve.sol";

/**
 * @title SqrtBondingCurveUsage
 * @dev Example usage patterns for the sqrt bonding curve implementation
 * @notice Demonstrates common integration patterns and best practices
 * @author OKX DeFi Platform
 */
contract SqrtBondingCurveUsage {
    BondingCurveV2 public immutable bondingCurve;
    
    // Events for example tracking
    event PurchaseExecuted(address indexed user, address indexed token, uint256 okbSpent, uint256 tokensReceived);
    event SaleExecuted(address indexed user, address indexed token, uint256 tokensSold, uint256 okbReceived);
    event GraduationDetected(address indexed token, uint256 finalSupply, uint256 totalCollected);
    
    constructor(address _bondingCurveAddress) {
        bondingCurve = BondingCurveV2(_bondingCurveAddress);
    }
    
    // ============ Basic Trading Examples ============
    
    /**
     * @dev Example 1: Simple token purchase with auto-slippage calculation
     * @param token Token contract address
     * @param maxSlippageBps Maximum acceptable slippage in basis points (e.g., 500 = 5%)
     */
    function buyTokensWithAutoSlippage(
        address token,
        uint256 maxSlippageBps
    ) external payable {
        require(msg.value > 0, "Must send OKB");
        require(maxSlippageBps <= 1000, "Slippage too high"); // Max 10%
        
        // Get quote for the purchase
        IBondingCurve.Quote memory quote = bondingCurve.getBuyQuote(token, msg.value);
        require(quote.isValid, "Invalid quote");
        
        // Calculate minimum tokens with slippage protection
        uint256 minTokens = quote.amount * (10000 - maxSlippageBps) / 10000;
        
        // Execute purchase
        (uint256 tokensReceived, uint256 fee) = bondingCurve.buyTokens{value: msg.value}(
            token,
            minTokens
        );
        
        emit PurchaseExecuted(msg.sender, token, msg.value, tokensReceived);
    }
    
    /**
     * @dev Example 2: Dollar cost averaging purchase
     * @param token Token contract address
     * @param targetOkbAmount Total OKB amount to spend over time
     * @param maxPriceImpactBps Maximum price impact per purchase (e.g., 100 = 1%)
     */
    function dollarCostAverage(
        address token,
        uint256 targetOkbAmount,
        uint256 maxPriceImpactBps
    ) external payable {
        require(msg.value <= targetOkbAmount, "Exceeds target amount");
        
        // Get quote and check price impact
        IBondingCurve.Quote memory quote = bondingCurve.getBuyQuote(token, msg.value);
        require(quote.isValid, "Invalid quote");
        require(quote.priceImpact <= maxPriceImpactBps, "Price impact too high");
        
        // Execute purchase with 2% slippage tolerance
        uint256 minTokens = quote.amount * 98 / 100;
        bondingCurve.buyTokens{value: msg.value}(token, minTokens);
    }
    
    /**
     * @dev Example 3: Limit order style purchase
     * @param token Token contract address
     * @param maxPricePerToken Maximum price willing to pay per token (in wei)
     */
    function limitBuyOrder(
        address token,
        uint256 maxPricePerToken
    ) external payable {
        // Get current market info
        IBondingCurve.MarketInfo memory info = bondingCurve.getMarketInfo(token);
        require(info.spotPrice <= maxPricePerToken, "Price above limit");
        
        // Execute purchase
        IBondingCurve.Quote memory quote = bondingCurve.getBuyQuote(token, msg.value);
        uint256 minTokens = quote.amount * 95 / 100; // 5% slippage
        
        bondingCurve.buyTokens{value: msg.value}(token, minTokens);
    }
    
    // ============ Advanced Trading Patterns ============
    
    /**
     * @dev Example 4: Graduation timing purchase
     * @param token Token contract address
     * @param graduationThresholdBps Purchase only when graduation is X% complete
     */
    function graduationTimingPurchase(
        address token,
        uint256 graduationThresholdBps
    ) external payable {
        // Check graduation progress
        (bool isReady, uint256 progress, uint256 threshold, uint256 collected) = 
            bondingCurve.getGraduationStatus(token);
        
        require(!isReady, "Already graduated");
        require(progress >= graduationThresholdBps, "Graduation not far enough");
        
        // Execute purchase
        IBondingCurve.Quote memory quote = bondingCurve.getBuyQuote(token, msg.value);
        uint256 minTokens = quote.amount * 97 / 100; // 3% slippage
        
        bondingCurve.buyTokens{value: msg.value}(token, minTokens);
    }
    
    /**
     * @dev Example 5: Batch quote comparison
     * @param tokens Array of token addresses to compare
     * @param okbAmount Amount of OKB to spend on each
     * @return bestToken Address of token with best expected return
     * @return bestQuote Quote information for the best token
     */
    function findBestBuyOpportunity(
        address[] calldata tokens,
        uint256 okbAmount
    ) external view returns (address bestToken, IBondingCurve.Quote memory bestQuote) {
        uint256 bestTokensPerOkb = 0;
        
        for (uint256 i = 0; i < tokens.length; i++) {
            if (!bondingCurve.isTokenAuthorized(tokens[i]) || 
                bondingCurve.isTokenGraduated(tokens[i])) {
                continue;
            }
            
            IBondingCurve.Quote memory quote = bondingCurve.getBuyQuote(tokens[i], okbAmount);
            if (!quote.isValid) continue;
            
            uint256 tokensPerOkb = quote.amount * 1e18 / okbAmount;
            if (tokensPerOkb > bestTokensPerOkb) {
                bestTokensPerOkb = tokensPerOkb;
                bestToken = tokens[i];
                bestQuote = quote;
            }
        }
        
        require(bestToken != address(0), "No valid opportunities found");
    }
    
    // ============ Selling Examples ============
    
    /**
     * @dev Example 6: Stop-loss sale
     * @param token Token contract address
     * @param tokenAmount Amount of tokens to sell
     * @param minPricePerToken Minimum acceptable price per token
     */
    function stopLossSale(
        address token,
        uint256 tokenAmount,
        uint256 minPricePerToken
    ) external {
        // Check current price
        uint256 currentPrice = bondingCurve.getSpotPrice(token);
        require(currentPrice >= minPricePerToken, "Price below stop loss");
        
        // Get sell quote
        IBondingCurve.Quote memory quote = bondingCurve.getSellQuote(token, tokenAmount);
        require(quote.isValid, "Invalid sell quote");
        
        // Execute sale with 5% slippage tolerance
        uint256 minOkb = quote.amount * 95 / 100;
        bondingCurve.sellTokens(token, tokenAmount, minOkb);
        
        emit SaleExecuted(msg.sender, token, tokenAmount, quote.amount);
    }
    
    /**
     * @dev Example 7: Profit taking at graduation
     * @param token Token contract address
     * @param tokenAmount Amount of tokens to sell
     */
    function graduationProfitTaking(
        address token,
        uint256 tokenAmount
    ) external {
        // Check if graduation is imminent (>90% complete)
        (, uint256 progress,,) = bondingCurve.getGraduationStatus(token);
        require(progress >= 9000, "Graduation not imminent"); // 90%
        
        // Execute sale
        IBondingCurve.Quote memory quote = bondingCurve.getSellQuote(token, tokenAmount);
        require(quote.isValid, "Invalid sell quote");
        
        uint256 minOkb = quote.amount * 97 / 100; // 3% slippage
        bondingCurve.sellTokens(token, tokenAmount, minOkb);
    }
    
    // ============ Market Analysis Examples ============
    
    /**
     * @dev Example 8: Market health checker
     * @param token Token contract address
     * @return marketHealth Struct containing key market metrics
     */
    function analyzeMarketHealth(address token) external view returns (MarketHealth memory marketHealth) {
        IBondingCurve.MarketInfo memory info = bondingCurve.getMarketInfo(token);
        
        marketHealth.token = token;
        marketHealth.currentPrice = info.spotPrice;
        marketHealth.marketCap = info.marketCap;
        marketHealth.graduationProgress = info.graduationProgress;
        
        // Calculate price vs initial price ratio
        if (info.currentSupply > 0) {
            uint256 initialPrice = 0.5 ether * 1e18 / 1_000_000 ether; // Based on constants
            marketHealth.priceMultiple = info.spotPrice * 100 / initialPrice; // 2x = 200
        }
        
        // Assess liquidity based on reserves
        if (info.reserves > 50 ether) {
            marketHealth.liquidityLevel = "High";
        } else if (info.reserves > 10 ether) {
            marketHealth.liquidityLevel = "Medium";
        } else {
            marketHealth.liquidityLevel = "Low";
        }
        
        // Check if good buying opportunity
        marketHealth.isBuyOpportunity = !info.isGraduationReady && info.graduationProgress < 5000; // <50%
    }
    
    /**
     * @dev Example 9: Multi-amount quote analysis
     * @param token Token contract address
     * @param amounts Array of OKB amounts to analyze
     * @return Analysis of price impact across different purchase sizes
     */
    function analyzePriceImpact(
        address token,
        uint256[] calldata amounts
    ) external view returns (PriceImpactAnalysis memory) {
        IBondingCurve.Quote[] memory quotes = bondingCurve.getMultipleQuotes(token, amounts, true);
        
        PriceImpactAnalysis memory analysis;
        analysis.token = token;
        analysis.amounts = amounts;
        analysis.priceImpacts = new uint256[](amounts.length);
        analysis.averagePriceImpact = 0;
        analysis.maxPriceImpact = 0;
        
        uint256 totalImpact = 0;
        uint256 validQuotes = 0;
        
        for (uint256 i = 0; i < quotes.length; i++) {
            if (quotes[i].isValid) {
                analysis.priceImpacts[i] = quotes[i].priceImpact;
                totalImpact += quotes[i].priceImpact;
                validQuotes++;
                
                if (quotes[i].priceImpact > analysis.maxPriceImpact) {
                    analysis.maxPriceImpact = quotes[i].priceImpact;
                }
            }
        }
        
        if (validQuotes > 0) {
            analysis.averagePriceImpact = totalImpact / validQuotes;
        }
        
        return analysis;
    }
    
    // ============ Monitoring and Events ============
    
    /**
     * @dev Example 10: Graduation monitor
     * @param token Token contract address
     * @notice Call this to emit graduation event when detected
     */
    function checkGraduationStatus(address token) external {
        (bool isReady,,uint256 threshold, uint256 collected) = bondingCurve.getGraduationStatus(token);
        
        if (isReady && !bondingCurve.isTokenGraduated(token)) {
            IBondingCurve.MarketInfo memory info = bondingCurve.getMarketInfo(token);
            emit GraduationDetected(token, info.currentSupply, collected);
        }
    }
    
    /**
     * @dev Example 11: Price change monitor
     * @param token Token contract address
     * @param lastKnownPrice Previous price to compare against
     * @return priceChangePercent Percentage change (positive or negative)
     * @return isSignificantChange True if change > 10%
     */
    function monitorPriceChange(
        address token,
        uint256 lastKnownPrice
    ) external view returns (int256 priceChangePercent, bool isSignificantChange) {
        uint256 currentPrice = bondingCurve.getSpotPrice(token);
        
        if (lastKnownPrice > 0) {
            if (currentPrice >= lastKnownPrice) {
                priceChangePercent = int256((currentPrice - lastKnownPrice) * 10000 / lastKnownPrice);
            } else {
                priceChangePercent = -int256((lastKnownPrice - currentPrice) * 10000 / lastKnownPrice);
            }
            
            isSignificantChange = priceChangePercent > 1000 || priceChangePercent < -1000; // >10%
        }
    }
    
    // ============ Structs for Analysis ============
    
    struct MarketHealth {
        address token;
        uint256 currentPrice;
        uint256 marketCap;
        uint256 graduationProgress;
        uint256 priceMultiple; // Price multiple from initial (100 = 1x)
        string liquidityLevel; // "High", "Medium", "Low"
        bool isBuyOpportunity;
    }
    
    struct PriceImpactAnalysis {
        address token;
        uint256[] amounts;
        uint256[] priceImpacts;
        uint256 averagePriceImpact;
        uint256 maxPriceImpact;
    }
    
    // ============ Utility Functions ============
    
    /**
     * @dev Calculate estimated tokens for OKB amount including fees
     */
    function estimateTokensAfterFees(
        address token,
        uint256 okbAmount
    ) external view returns (uint256 tokensReceived, uint256 fees, uint256 priceImpact) {
        IBondingCurve.Quote memory quote = bondingCurve.getBuyQuote(token, okbAmount);
        if (quote.isValid) {
            tokensReceived = quote.amount;
            fees = quote.fee;
            priceImpact = quote.priceImpact;
        }
    }
    
    /**
     * @dev Get comprehensive token statistics
     */
    function getTokenStats(address token) external view returns (
        uint256 spotPrice,
        uint256 marketCap,
        uint256 graduationProgress,
        bool isGraduationReady,
        string memory curveType,
        string memory version
    ) {
        IBondingCurve.MarketInfo memory info = bondingCurve.getMarketInfo(token);
        
        spotPrice = info.spotPrice;
        marketCap = info.marketCap;
        graduationProgress = info.graduationProgress;
        isGraduationReady = info.isGraduationReady;
        curveType = bondingCurve.getCurveType();
        version = bondingCurve.getVersion();
    }
    
    /**
     * @dev Emergency function to check if user can trade (anti-bot check)
     */
    function canUserTrade(address user, address token) external view returns (bool) {
        // This would require additional view functions in the main contract
        // For now, return true as example
        return bondingCurve.isTokenAuthorized(token) && !bondingCurve.isTokenGraduated(token);
    }
}