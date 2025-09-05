// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./MemeToken.sol";
import "./BondingCurve.sol";

/**
 * @title TokenFactory
 * @dev Factory contract for creating meme tokens with bonding curves
 * @notice Creates new meme tokens and integrates them with bonding curve trading
 */
contract TokenFactory is Ownable, ReentrancyGuard, Pausable {
    // Constants
    uint256 public constant CREATION_FEE = 0.1 ether; // 0.1 OKB to create token
    uint256 public constant DEFAULT_MAX_SUPPLY = 1000000 ether; // 1M tokens default
    
    // State variables
    BondingCurve public immutable bondingCurve;
    
    // Token tracking
    address[] public allTokens;
    mapping(address => bool) public isTokenFromFactory;
    mapping(address => TokenInfo) public tokenInfo;
    mapping(string => bool) public symbolTaken;
    mapping(address => address[]) public creatorTokens;
    
    // Statistics
    uint256 public totalTokensCreated;
    uint256 public totalFeesCollected;
    
    struct TokenInfo {
        address creator;
        uint256 createdAt;
        string name;
        string symbol;
        string description;
        string imageUrl;
        string website;
        string telegram;
        string twitter;
        uint256 maxSupply;
        bool isActive;
    }
    
    // Events
    event TokenCreated(
        address indexed token,
        address indexed creator,
        string name,
        string symbol,
        string description,
        string imageUrl,
        uint256 maxSupply,
        uint256 timestamp
    );
    
    event TokenDeactivated(address indexed token, uint256 timestamp);
    event CreationFeeUpdated(uint256 newFee);
    
    /**
     * @dev Constructor
     * @param _bondingCurve Address of bonding curve contract
     */
    constructor(address _bondingCurve) {
        require(_bondingCurve != address(0), "Invalid bonding curve");
        bondingCurve = BondingCurve(_bondingCurve);
    }
    
    /**
     * @dev Create a new meme token
     * @param name Token name
     * @param symbol Token symbol (must be unique)
     * @param description Token description
     * @param imageUrl Token image URL
     * @param website Website URL (optional)
     * @param telegram Telegram URL (optional)
     * @param twitter Twitter URL (optional)
     * @param maxSupply Maximum token supply (0 for default)
     */
    function createToken(
        string calldata name,
        string calldata symbol,
        string calldata description,
        string calldata imageUrl,
        string calldata website,
        string calldata telegram,
        string calldata twitter,
        uint256 maxSupply
    ) external payable nonReentrant whenNotPaused returns (address tokenAddress) {
        require(msg.value >= CREATION_FEE, "Insufficient creation fee");
        require(bytes(name).length > 0 && bytes(name).length <= 50, "Invalid name length");
        require(bytes(symbol).length > 0 && bytes(symbol).length <= 10, "Invalid symbol length");
        require(bytes(description).length > 0 && bytes(description).length <= 500, "Invalid description length");
        require(bytes(imageUrl).length > 0, "Image URL required");
        require(!symbolTaken[symbol], "Symbol already taken");
        
        // Use default max supply if not specified
        if (maxSupply == 0) {
            maxSupply = DEFAULT_MAX_SUPPLY;
        }
        require(maxSupply >= 1000 ether && maxSupply <= 1000000000 ether, "Invalid max supply");
        
        // Mark symbol as taken
        symbolTaken[symbol] = true;
        
        // Create the token
        MemeToken newToken = new MemeToken(
            name,
            symbol,
            description,
            imageUrl,
            maxSupply,
            address(this), // Factory owns initially
            address(bondingCurve)
        );
        
        tokenAddress = address(newToken);
        
        // Update metadata with social links
        newToken.updateMetadata(description, imageUrl, website, telegram, twitter);
        
        // Transfer ownership to creator
        newToken.transferOwnership(msg.sender);
        
        // Authorize token in bonding curve
        bondingCurve.setTokenAuthorization(tokenAddress, true);
        
        // Store token info
        tokenInfo[tokenAddress] = TokenInfo({
            creator: msg.sender,
            createdAt: block.timestamp,
            name: name,
            symbol: symbol,
            description: description,
            imageUrl: imageUrl,
            website: website,
            telegram: telegram,
            twitter: twitter,
            maxSupply: maxSupply,
            isActive: true
        });
        
        // Update tracking
        allTokens.push(tokenAddress);
        creatorTokens[msg.sender].push(tokenAddress);
        isTokenFromFactory[tokenAddress] = true;
        totalTokensCreated++;
        totalFeesCollected += msg.value;
        
        emit TokenCreated(
            tokenAddress,
            msg.sender,
            name,
            symbol,
            description,
            imageUrl,
            maxSupply,
            block.timestamp
        );
        
        // Refund excess payment
        if (msg.value > CREATION_FEE) {
            (bool success,) = msg.sender.call{value: msg.value - CREATION_FEE}("");
            require(success, "Refund failed");
        }
    }
    
    /**
     * @dev Deactivate a token (creator only)
     * @param token Token address to deactivate
     */
    function deactivateToken(address token) external {
        require(isTokenFromFactory[token], "Not a factory token");
        require(tokenInfo[token].creator == msg.sender || msg.sender == owner(), "Not authorized");
        require(tokenInfo[token].isActive, "Already deactivated");
        
        tokenInfo[token].isActive = false;
        bondingCurve.setTokenAuthorization(token, false);
        
        emit TokenDeactivated(token, block.timestamp);
    }
    
    /**
     * @dev Get all tokens created by a specific creator
     * @param creator Creator address
     * @return tokens Array of token addresses
     */
    function getTokensByCreator(address creator) external view returns (address[] memory tokens) {
        return creatorTokens[creator];
    }
    
    /**
     * @dev Get token information
     * @param token Token address
     * @return info TokenInfo struct
     */
    function getTokenInfo(address token) external view returns (TokenInfo memory info) {
        require(isTokenFromFactory[token], "Not a factory token");
        return tokenInfo[token];
    }
    
    /**
     * @dev Get all tokens (paginated)
     * @param offset Starting index
     * @param limit Maximum number of results
     * @return tokens Array of token addresses
     * @return total Total number of tokens
     */
    function getAllTokens(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory tokens, uint256 total) {
        total = allTokens.length;
        
        if (offset >= total) {
            return (new address[](0), total);
        }
        
        uint256 end = offset + limit;
        if (end > total) {
            end = total;
        }
        
        tokens = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            tokens[i - offset] = allTokens[i];
        }
    }
    
    /**
     * @dev Get active tokens only (paginated)
     * @param offset Starting index
     * @param limit Maximum number of results
     * @return tokens Array of active token addresses
     */
    function getActiveTokens(
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory tokens) {
        // Count active tokens first
        uint256 activeCount = 0;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (tokenInfo[allTokens[i]].isActive) {
                activeCount++;
            }
        }
        
        if (offset >= activeCount) {
            return new address[](0);
        }
        
        uint256 end = offset + limit;
        if (end > activeCount) {
            end = activeCount;
        }
        
        tokens = new address[](end - offset);
        uint256 currentIndex = 0;
        uint256 resultIndex = 0;
        
        for (uint256 i = 0; i < allTokens.length && resultIndex < (end - offset); i++) {
            if (tokenInfo[allTokens[i]].isActive) {
                if (currentIndex >= offset) {
                    tokens[resultIndex] = allTokens[i];
                    resultIndex++;
                }
                currentIndex++;
            }
        }
    }
    
    /**
     * @dev Check if a symbol is available
     * @param symbol Symbol to check
     * @return available True if symbol is available
     */
    function isSymbolAvailable(string calldata symbol) external view returns (bool available) {
        return !symbolTaken[symbol];
    }
    
    /**
     * @dev Get factory statistics
     * @return stats Factory statistics
     */
    function getFactoryStats() external view returns (
        uint256 totalTokens,
        uint256 totalFees,
        uint256 creationFee
    ) {
        return (totalTokensCreated, totalFeesCollected, CREATION_FEE);
    }
    
    /**
     * @dev Withdraw collected fees (owner only)
     * @param amount Amount to withdraw (0 for all)
     */
    function withdrawFees(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        if (amount == 0 || amount > balance) {
            amount = balance;
        }
        
        (bool success,) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @dev Pause/unpause token creation
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }
    
    /**
     * @dev Emergency function to recover stuck tokens
     * @param token Token address to recover
     * @param amount Amount to recover
     */
    function emergencyRecoverToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
    
    /**
     * @dev Fallback function to receive OKB
     */
    receive() external payable {
        totalFeesCollected += msg.value;
    }
}