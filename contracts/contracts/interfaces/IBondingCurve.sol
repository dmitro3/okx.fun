// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IBondingCurve
 * @dev Interface for bonding curve implementations
 * @notice Defines the standard interface for bonding curve trading contracts
 * @author OKX DeFi Platform
 */
interface IBondingCurve {
    
    // ============ Structs ============
    
    /**
     * @dev Market information structure
     */
    struct MarketInfo {
        uint256 currentSupply;
        uint256 marketCap;
        uint256 spotPrice;
        uint256 totalOKBCollected;
        uint256 reserves;
        bool isGraduationReady;
        uint256 graduationProgress;
        uint256 virtualReserves;
    }

    /**
     * @dev Quote information structure
     */
    struct Quote {
        uint256 amount;
        uint256 fee;
        uint256 priceImpact;
        uint256 minReceived;
        bool isValid;
    }

    /**
     * @dev Trading parameters structure
     */
    struct TradingParams {
        address token;
        uint256 amount;
        uint256 minAmount;
        uint256 deadline;
        bytes extraData;
    }

    // ============ Events ============

    /**
     * @dev Emitted when tokens are purchased
     * @param token Token contract address
     * @param buyer Address of the buyer
     * @param okbAmount Amount of OKB spent
     * @param tokenAmount Amount of tokens received
     * @param fee Fee amount paid
     * @param newPrice New spot price after purchase
     * @param totalOKBCollected Updated total OKB collected
     */
    event TokensPurchased(
        address indexed token,
        address indexed buyer,
        uint256 okbAmount,
        uint256 tokenAmount,
        uint256 fee,
        uint256 newPrice,
        uint256 totalOKBCollected
    );

    /**
     * @dev Emitted when tokens are sold
     * @param token Token contract address
     * @param seller Address of the seller
     * @param tokenAmount Amount of tokens sold
     * @param okbAmount Amount of OKB received
     * @param fee Fee amount paid
     * @param newPrice New spot price after sale
     * @param totalOKBCollected Updated total OKB collected
     */
    event TokensSold(
        address indexed token,
        address indexed seller,
        uint256 tokenAmount,
        uint256 okbAmount,
        uint256 fee,
        uint256 newPrice,
        uint256 totalOKBCollected
    );

    /**
     * @dev Emitted when a token graduates to DEX
     * @param token Token contract address
     * @param finalSupply Final supply at graduation
     * @param totalOKBCollected Total OKB collected during bonding curve phase
     * @param liquidityOKB OKB amount used for DEX liquidity
     * @param liquidityTokens Token amount used for DEX liquidity
     * @param timestamp Graduation timestamp
     */
    event TokenGraduated(
        address indexed token,
        uint256 finalSupply,
        uint256 totalOKBCollected,
        uint256 liquidityOKB,
        uint256 liquidityTokens,
        uint256 timestamp
    );

    /**
     * @dev Emitted when token authorization status changes
     * @param token Token contract address
     * @param authorized New authorization status
     * @param authorizer Address that changed the authorization
     */
    event TokenAuthorizationChanged(
        address indexed token,
        bool authorized,
        address indexed authorizer
    );

    /**
     * @dev Emitted when reserves are updated
     * @param token Token contract address
     * @param oldReserves Previous reserve amount
     * @param newReserves New reserve amount
     * @param reserveType Type of reserves (OKB, virtual, etc.)
     */
    event ReservesUpdated(
        address indexed token,
        uint256 oldReserves,
        uint256 newReserves,
        string reserveType
    );

    // ============ Core Trading Functions ============

    /**
     * @dev Buy tokens with OKB using bonding curve
     * @param token Token contract address
     * @param minTokenAmount Minimum tokens to receive (slippage protection)
     * @return tokenAmount Actual amount of tokens received
     * @return fee Fee amount paid
     */
    function buyTokens(
        address token,
        uint256 minTokenAmount
    ) external payable returns (uint256 tokenAmount, uint256 fee);

    /**
     * @dev Sell tokens for OKB using bonding curve
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
    ) external returns (uint256 okbAmount, uint256 fee);

    /**
     * @dev Buy tokens with advanced parameters
     * @param params Trading parameters structure
     * @return tokenAmount Actual amount of tokens received
     * @return fee Fee amount paid
     */
    function buyTokensAdvanced(
        TradingParams calldata params
    ) external payable returns (uint256 tokenAmount, uint256 fee);

    /**
     * @dev Sell tokens with advanced parameters
     * @param params Trading parameters structure
     * @return okbAmount Actual amount of OKB received
     * @return fee Fee amount paid
     */
    function sellTokensAdvanced(
        TradingParams calldata params
    ) external returns (uint256 okbAmount, uint256 fee);

    // ============ Quote Functions ============

    /**
     * @dev Get quote for buying tokens
     * @param token Token contract address
     * @param okbAmount Amount of OKB to spend
     * @return quote Quote information including amount, fee, and price impact
     */
    function getBuyQuote(
        address token,
        uint256 okbAmount
    ) external view returns (Quote memory quote);

    /**
     * @dev Get quote for selling tokens
     * @param token Token contract address
     * @param tokenAmount Amount of tokens to sell
     * @return quote Quote information including amount, fee, and price impact
     */
    function getSellQuote(
        address token,
        uint256 tokenAmount
    ) external view returns (Quote memory quote);

    /**
     * @dev Get multiple quotes for different amounts
     * @param token Token contract address
     * @param amounts Array of amounts to get quotes for
     * @param isBuy True for buy quotes, false for sell quotes
     * @return quotes Array of quote information
     */
    function getMultipleQuotes(
        address token,
        uint256[] calldata amounts,
        bool isBuy
    ) external view returns (Quote[] memory quotes);

    // ============ Market Information Functions ============

    /**
     * @dev Get comprehensive token market information
     * @param token Token contract address
     * @return info Market information structure
     */
    function getMarketInfo(address token) external view returns (MarketInfo memory info);

    /**
     * @dev Get current spot price for a token
     * @param token Token contract address
     * @return price Current spot price in OKB per token
     */
    function getSpotPrice(address token) external view returns (uint256 price);

    /**
     * @dev Get current market cap for a token
     * @param token Token contract address
     * @return marketCap Current market capitalization in OKB
     */
    function getMarketCap(address token) external view returns (uint256 marketCap);

    /**
     * @dev Get graduation status and progress
     * @param token Token contract address
     * @return isReady True if ready for graduation
     * @return progress Graduation progress in basis points (0-10000)
     * @return threshold OKB threshold for graduation
     * @return collected Total OKB collected so far
     */
    function getGraduationStatus(address token) external view returns (
        bool isReady,
        uint256 progress,
        uint256 threshold,
        uint256 collected
    );

    // ============ Admin Functions ============

    /**
     * @dev Set token authorization status
     * @param token Token contract address
     * @param authorized Authorization status
     */
    function setTokenAuthorization(address token, bool authorized) external;

    /**
     * @dev Update bonding curve parameters
     * @param token Token contract address
     * @param params New parameters (implementation-specific)
     */
    function updateCurveParameters(address token, bytes calldata params) external;

    /**
     * @dev Emergency pause/unpause trading
     * @param paused Pause status
     */
    function setPaused(bool paused) external;

    /**
     * @dev Update fee parameters
     * @param newFeeBasisPoints New fee in basis points
     */
    function updateFee(uint256 newFeeBasisPoints) external;

    // ============ View Functions ============

    /**
     * @dev Check if token is authorized for trading
     * @param token Token contract address
     * @return authorized True if authorized
     */
    function isTokenAuthorized(address token) external view returns (bool authorized);

    /**
     * @dev Check if token has graduated
     * @param token Token contract address
     * @return graduated True if graduated
     */
    function isTokenGraduated(address token) external view returns (bool graduated);

    /**
     * @dev Get current fee rate
     * @return feeBasisPoints Current fee in basis points
     */
    function getCurrentFee() external view returns (uint256 feeBasisPoints);

    /**
     * @dev Get total fees collected
     * @return totalFees Total fees collected across all tokens
     */
    function getTotalFeesCollected() external view returns (uint256 totalFees);

    /**
     * @dev Get reserves for a specific token
     * @param token Token contract address
     * @return okbReserves OKB reserves for the token
     * @return virtualReserves Virtual reserves for the token
     */
    function getReserves(address token) external view returns (
        uint256 okbReserves,
        uint256 virtualReserves
    );

    /**
     * @dev Get bonding curve type identifier
     * @return curveType Curve type (e.g., "linear", "sqrt", "exponential")
     */
    function getCurveType() external pure returns (string memory curveType);

    /**
     * @dev Get bonding curve version
     * @return version Version string
     */
    function getVersion() external pure returns (string memory version);

    // ============ Batch Operations ============

    /**
     * @dev Execute multiple buy operations in a single transaction
     * @param tokens Array of token addresses
     * @param amounts Array of OKB amounts to spend
     * @param minTokenAmounts Array of minimum token amounts to receive
     * @return tokenAmounts Array of actual token amounts received
     * @return totalFees Total fees paid across all operations
     */
    function batchBuy(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata minTokenAmounts
    ) external payable returns (uint256[] memory tokenAmounts, uint256 totalFees);

    /**
     * @dev Execute multiple sell operations in a single transaction
     * @param tokens Array of token addresses
     * @param tokenAmounts Array of token amounts to sell
     * @param minOkbAmounts Array of minimum OKB amounts to receive
     * @return okbAmounts Array of actual OKB amounts received
     * @return totalFees Total fees paid across all operations
     */
    function batchSell(
        address[] calldata tokens,
        uint256[] calldata tokenAmounts,
        uint256[] calldata minOkbAmounts
    ) external returns (uint256[] memory okbAmounts, uint256 totalFees);

    // ============ Integration Functions ============

    /**
     * @dev Initialize a new token for bonding curve trading
     * @param token Token contract address
     * @param initialParams Initial parameters for the bonding curve
     * @return success True if initialization was successful
     */
    function initializeToken(
        address token,
        bytes calldata initialParams
    ) external returns (bool success);

    /**
     * @dev Manually trigger graduation for a token (admin only)
     * @param token Token contract address
     * @return success True if graduation was successful
     */
    function manualGraduation(address token) external returns (bool success);

    /**
     * @dev Get contract's supported features
     * @return features Array of supported feature identifiers
     */
    function getSupportedFeatures() external pure returns (string[] memory features);
}