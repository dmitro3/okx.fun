// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title MemeToken
 * @dev ERC-20 token template for meme tokens on X Layer Fun
 * @notice Template contract for bonding curve tokens with special features
 */
contract MemeToken is ERC20, ERC20Burnable, Ownable, Pausable {
    // Token metadata
    string public description;
    string public imageUrl;
    string public website;
    string public telegram;
    string public twitter;
    
    // Token economics
    uint256 public immutable maxSupply;
    uint256 public marketCap;
    bool public isGraduated;
    address public bondingCurve;
    address public liquidityPool;
    
    // Events
    event MetadataUpdated(
        string description,
        string imageUrl,
        string website,
        string telegram,
        string twitter
    );
    event Graduated(address indexed liquidityPool, uint256 timestamp);
    event MarketCapUpdated(uint256 newMarketCap);
    
    /**
     * @dev Constructor for MemeToken
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _description Token description
     * @param _imageUrl Token image URL
     * @param _maxSupply Maximum token supply
     * @param _initialOwner Initial owner address
     * @param _bondingCurve Bonding curve contract address
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _imageUrl,
        uint256 _maxSupply,
        address _initialOwner,
        address _bondingCurve
    ) ERC20(_name, _symbol) {
        require(_maxSupply > 0, "Max supply must be > 0");
        require(_initialOwner != address(0), "Invalid initial owner");
        require(_bondingCurve != address(0), "Invalid bonding curve");
        
        description = _description;
        imageUrl = _imageUrl;
        maxSupply = _maxSupply;
        bondingCurve = _bondingCurve;
        
        _transferOwnership(_initialOwner);
        
        // Mint initial supply to bonding curve
        _mint(_bondingCurve, _maxSupply);
    }
    
    /**
     * @dev Update token metadata (only owner)
     * @param _description New description
     * @param _imageUrl New image URL
     * @param _website Website URL
     * @param _telegram Telegram URL
     * @param _twitter Twitter URL
     */
    function updateMetadata(
        string calldata _description,
        string calldata _imageUrl,
        string calldata _website,
        string calldata _telegram,
        string calldata _twitter
    ) external onlyOwner {
        description = _description;
        imageUrl = _imageUrl;
        website = _website;
        telegram = _telegram;
        twitter = _twitter;
        
        emit MetadataUpdated(_description, _imageUrl, _website, _telegram, _twitter);
    }
    
    /**
     * @dev Mark token as graduated and set liquidity pool
     * @param _liquidityPool Address of the liquidity pool
     */
    function graduate(address _liquidityPool) external {
        require(msg.sender == bondingCurve, "Only bonding curve can graduate");
        require(!isGraduated, "Already graduated");
        require(_liquidityPool != address(0), "Invalid liquidity pool");
        
        isGraduated = true;
        liquidityPool = _liquidityPool;
        
        emit Graduated(_liquidityPool, block.timestamp);
    }
    
    /**
     * @dev Update market cap (only bonding curve)
     * @param _marketCap New market cap value
     */
    function updateMarketCap(uint256 _marketCap) external {
        require(msg.sender == bondingCurve, "Only bonding curve can update");
        marketCap = _marketCap;
        emit MarketCapUpdated(_marketCap);
    }
    
    /**
     * @dev Pause token transfers (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause token transfers (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Get complete token information
     * @return info Struct containing all token information
     */
    function getTokenInfo() external view returns (
        string memory name,
        string memory symbol,
        string memory desc,
        string memory image,
        string memory web,
        string memory tg,
        string memory tw,
        uint256 supply,
        uint256 maxSup,
        uint256 marketCap_,
        bool graduated,
        address pool
    ) {
        return (
            name(),
            symbol(),
            description,
            imageUrl,
            website,
            telegram,
            twitter,
            totalSupply(),
            maxSupply,
            marketCap,
            isGraduated,
            liquidityPool
        );
    }
    
    /**
     * @dev Override transfer to include pause functionality
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "Token transfers are paused");
    }
    
    /**
     * @dev Get circulating supply (excludes bonding curve holdings)
     * @return circulating Circulating supply amount
     */
    function circulatingSupply() external view returns (uint256 circulating) {
        return totalSupply() - balanceOf(bondingCurve);
    }
    
    /**
     * @dev Check if token has enough liquidity for graduation
     * @return ready True if ready for graduation
     */
    function isReadyForGraduation() external view returns (bool ready) {
        // This would be called by bonding curve to check graduation criteria
        return marketCap >= 50000 ether; // $50,000 market cap
    }
}