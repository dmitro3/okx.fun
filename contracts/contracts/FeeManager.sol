// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title FeeManager
 * @dev Manages fee collection and distribution for the X Layer Fun platform
 * @notice Handles fees from bonding curve trading and post-graduation DEX fees
 */
contract FeeManager is ReentrancyGuard, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    // Access control roles
    bytes32 public constant FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    // Fee distribution structure
    struct FeeDistribution {
        address recipient;
        uint256 percentage; // Basis points (10000 = 100%)
        bool isActive;
        string description;
    }
    
    // State variables
    mapping(address => FeeDistribution[]) public feeDistributions; // token => distributions
    mapping(address => uint256) public totalFeesCollected; // token => total fees
    mapping(address => uint256) public totalFeesDistributed; // token => distributed fees
    mapping(address => mapping(address => uint256)) public recipientFees; // token => recipient => amount
    
    // Default distribution (for OKB and new tokens)
    FeeDistribution[] public defaultDistribution;
    
    // Platform addresses
    address public treasury;
    address public developmentFund;
    address public liquidityIncentives;
    address public tokenCreatorRewards;
    
    // Fee tracking
    address[] public feeTokens; // All tokens that have collected fees
    mapping(address => bool) public isRegisteredToken;
    uint256 public totalDistributionEvents;
    
    // Events
    event FeesCollected(
        address indexed token,
        address indexed from,
        uint256 amount,
        uint256 timestamp
    );
    
    event FeesDistributed(
        address indexed token,
        uint256 totalAmount,
        uint256 distributionId,
        uint256 timestamp
    );
    
    event FeeDistributionUpdated(
        address indexed token,
        address indexed recipient,
        uint256 percentage,
        bool isActive
    );
    
    event RecipientPaid(
        address indexed token,
        address indexed recipient,
        uint256 amount,
        string description
    );
    
    event DefaultDistributionUpdated(uint256 distributionCount);
    
    /**
     * @dev Constructor
     * @param _treasury Treasury address
     * @param _developmentFund Development fund address
     * @param _liquidityIncentives Liquidity incentives address
     * @param _tokenCreatorRewards Token creator rewards address
     */
    constructor(
        address _treasury,
        address _developmentFund,
        address _liquidityIncentives,
        address _tokenCreatorRewards
    ) {
        require(_treasury != address(0), "Invalid treasury");
        require(_developmentFund != address(0), "Invalid development fund");
        require(_liquidityIncentives != address(0), "Invalid liquidity incentives");
        require(_tokenCreatorRewards != address(0), "Invalid creator rewards");
        
        treasury = _treasury;
        developmentFund = _developmentFund;
        liquidityIncentives = _liquidityIncentives;
        tokenCreatorRewards = _tokenCreatorRewards;
        
        // Setup access control
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(FEE_COLLECTOR_ROLE, msg.sender);
        _grantRole(DISTRIBUTOR_ROLE, msg.sender);
        
        // Setup default distribution (percentages in basis points)
        _setupDefaultDistribution();
    }
    
    /**
     * @dev Setup default fee distribution
     */
    function _setupDefaultDistribution() private {
        // Treasury: 40%
        defaultDistribution.push(FeeDistribution({
            recipient: treasury,
            percentage: 4000,
            isActive: true,
            description: "Platform Treasury"
        }));
        
        // Development Fund: 25%
        defaultDistribution.push(FeeDistribution({
            recipient: developmentFund,
            percentage: 2500,
            isActive: true,
            description: "Development Fund"
        }));
        
        // Liquidity Incentives: 20%
        defaultDistribution.push(FeeDistribution({
            recipient: liquidityIncentives,
            percentage: 2000,
            isActive: true,
            description: "Liquidity Incentives"
        }));
        
        // Token Creator Rewards: 15%
        defaultDistribution.push(FeeDistribution({
            recipient: tokenCreatorRewards,
            percentage: 1500,
            isActive: true,
            description: "Token Creator Rewards"
        }));
    }
    
    /**
     * @dev Collect fees (called by bonding curve or other fee sources)
     * @param token Token address (address(0) for OKB)
     */
    function collectFees(address token) external payable nonReentrant onlyRole(FEE_COLLECTOR_ROLE) {
        uint256 amount;
        
        if (token == address(0)) {
            // OKB fees
            amount = msg.value;
            require(amount > 0, "No OKB fees to collect");
        } else {
            // ERC20 token fees - check balance increase
            amount = IERC20(token).balanceOf(address(this));
            require(amount > totalFeesCollected[token], "No new token fees to collect");
            amount = amount - totalFeesCollected[token];
        }
        
        // Register token if not already registered
        if (!isRegisteredToken[token]) {
            feeTokens.push(token);
            isRegisteredToken[token] = true;
        }
        
        totalFeesCollected[token] += amount;
        
        emit FeesCollected(token, msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Distribute collected fees
     * @param token Token address to distribute fees for
     */
    function distributeFees(address token) external nonReentrant onlyRole(DISTRIBUTOR_ROLE) whenNotPaused {
        uint256 availableAmount = totalFeesCollected[token] - totalFeesDistributed[token];
        require(availableAmount > 0, "No fees to distribute");
        
        FeeDistribution[] memory distributions = feeDistributions[token].length > 0 
            ? feeDistributions[token] 
            : defaultDistribution;
        
        uint256 totalDistributed = 0;
        uint256 distributionId = totalDistributionEvents++;
        
        for (uint256 i = 0; i < distributions.length; i++) {
            FeeDistribution memory dist = distributions[i];
            
            if (!dist.isActive) continue;
            
            uint256 amount = availableAmount * dist.percentage / 10000;
            if (amount == 0) continue;
            
            // Transfer fees to recipient
            if (token == address(0)) {
                // OKB transfer
                (bool success,) = dist.recipient.call{value: amount}("");
                require(success, "OKB transfer failed");
            } else {
                // ERC20 transfer
                IERC20(token).safeTransfer(dist.recipient, amount);
            }
            
            recipientFees[token][dist.recipient] += amount;
            totalDistributed += amount;
            
            emit RecipientPaid(token, dist.recipient, amount, dist.description);
        }
        
        totalFeesDistributed[token] += totalDistributed;
        
        emit FeesDistributed(token, totalDistributed, distributionId, block.timestamp);
    }
    
    /**
     * @dev Set fee distribution for a specific token
     * @param token Token address
     * @param distributions Array of fee distributions
     */
    function setTokenFeeDistribution(
        address token,
        FeeDistribution[] calldata distributions
    ) external onlyRole(ADMIN_ROLE) {
        require(distributions.length > 0, "Empty distributions array");
        
        // Validate total percentage
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < distributions.length; i++) {
            require(distributions[i].recipient != address(0), "Invalid recipient");
            if (distributions[i].isActive) {
                totalPercentage += distributions[i].percentage;
            }
        }
        require(totalPercentage == 10000, "Total percentage must be 100%");
        
        // Clear existing distributions
        delete feeDistributions[token];
        
        // Add new distributions
        for (uint256 i = 0; i < distributions.length; i++) {
            feeDistributions[token].push(distributions[i]);
            
            emit FeeDistributionUpdated(
                token,
                distributions[i].recipient,
                distributions[i].percentage,
                distributions[i].isActive
            );
        }
    }
    
    /**
     * @dev Update default fee distribution
     * @param distributions New default distributions
     */
    function updateDefaultDistribution(
        FeeDistribution[] calldata distributions
    ) external onlyRole(ADMIN_ROLE) {
        require(distributions.length > 0, "Empty distributions array");
        
        // Validate total percentage
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < distributions.length; i++) {
            require(distributions[i].recipient != address(0), "Invalid recipient");
            if (distributions[i].isActive) {
                totalPercentage += distributions[i].percentage;
            }
        }
        require(totalPercentage == 10000, "Total percentage must be 100%");
        
        // Clear existing default distribution
        delete defaultDistribution;
        
        // Add new distributions
        for (uint256 i = 0; i < distributions.length; i++) {
            defaultDistribution.push(distributions[i]);
        }
        
        emit DefaultDistributionUpdated(distributions.length);
    }
    
    /**
     * @dev Update platform addresses
     * @param _treasury New treasury address
     * @param _developmentFund New development fund address
     * @param _liquidityIncentives New liquidity incentives address
     * @param _tokenCreatorRewards New token creator rewards address
     */
    function updatePlatformAddresses(
        address _treasury,
        address _developmentFund,
        address _liquidityIncentives,
        address _tokenCreatorRewards
    ) external onlyRole(ADMIN_ROLE) {
        require(_treasury != address(0), "Invalid treasury");
        require(_developmentFund != address(0), "Invalid development fund");
        require(_liquidityIncentives != address(0), "Invalid liquidity incentives");
        require(_tokenCreatorRewards != address(0), "Invalid creator rewards");
        
        treasury = _treasury;
        developmentFund = _developmentFund;
        liquidityIncentives = _liquidityIncentives;
        tokenCreatorRewards = _tokenCreatorRewards;
        
        // Update default distribution
        _setupDefaultDistribution();
    }
    
    /**
     * @dev Get fee distribution for a token
     * @param token Token address
     * @return distributions Array of fee distributions
     */
    function getTokenFeeDistribution(
        address token
    ) external view returns (FeeDistribution[] memory distributions) {
        if (feeDistributions[token].length > 0) {
            return feeDistributions[token];
        } else {
            return defaultDistribution;
        }
    }
    
    /**
     * @dev Get default fee distribution
     * @return distributions Default fee distributions
     */
    function getDefaultDistribution() external view returns (FeeDistribution[] memory distributions) {
        return defaultDistribution;
    }
    
    /**
     * @dev Get fee statistics for a token
     * @param token Token address
     * @return collected Total fees collected
     * @return distributed Total fees distributed
     * @return pending Pending fees for distribution
     */
    function getFeeStats(address token) external view returns (
        uint256 collected,
        uint256 distributed,
        uint256 pending
    ) {
        collected = totalFeesCollected[token];
        distributed = totalFeesDistributed[token];
        pending = collected - distributed;
    }
    
    /**
     * @dev Get all tokens that have collected fees
     * @return tokens Array of token addresses
     */
    function getAllFeeTokens() external view returns (address[] memory tokens) {
        return feeTokens;
    }
    
    /**
     * @dev Get recipient fee history
     * @param token Token address
     * @param recipient Recipient address
     * @return amount Total amount received by recipient
     */
    function getRecipientFees(address token, address recipient) external view returns (uint256 amount) {
        return recipientFees[token][recipient];
    }
    
    /**
     * @dev Emergency withdraw function (admin only)
     * @param token Token address (address(0) for OKB)
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(
        address token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (token == address(0)) {
            require(address(this).balance >= amount, "Insufficient OKB balance");
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "OKB transfer failed");
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }
    }
    
    /**
     * @dev Pause fee operations
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }
    
    /**
     * @dev Unpause fee operations
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
    
    /**
     * @dev Fallback function to receive OKB fees
     */
    receive() external payable {
        // Automatically collect OKB fees when received
        if (msg.value > 0) {
            totalFeesCollected[address(0)] += msg.value;
            
            if (!isRegisteredToken[address(0)]) {
                feeTokens.push(address(0));
                isRegisteredToken[address(0)] = true;
            }
            
            emit FeesCollected(address(0), msg.sender, msg.value, block.timestamp);
        }
    }
}