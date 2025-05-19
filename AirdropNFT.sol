
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AirdropNFT is ERC721Enumerable, Ownable, IERC2981 {
    using Strings for uint256;
    
    // Maximum supply of tokens
    uint256 public immutable maxSupply;
    
    // Base URI for metadata
    string private baseURI;
    
    // Royalty information
    address private royaltyReceiver;
    uint96 private royaltyPercentage;
    
    // Events
    event Airdropped(address indexed to, uint256 tokenId);
    event BatchAirdropped(address[] recipients, uint256 startTokenId, uint256 quantity);
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _initialBaseURI,
        address _royaltyReceiver,
        uint96 _royaltyPercentage
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        maxSupply = _maxSupply;
        baseURI = _initialBaseURI;
        royaltyReceiver = _royaltyReceiver;
        royaltyPercentage = _royaltyPercentage;
    }
    
    // Helper function to check if token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= totalSupply();
    }
    
    // Single airdrop function
    function airdrop(address to) external onlyOwner returns (uint256) {
        uint256 supply = totalSupply();
        require(supply < maxSupply, "Max supply reached");
        
        uint256 tokenId = supply + 1;
        _safeMint(to, tokenId);
        
        emit Airdropped(to, tokenId);
        
        return tokenId;
    }
    
    // Batch airdrop function
    function airdropBatch(address[] calldata recipients) external onlyOwner returns (uint256) {
        uint256 quantity = recipients.length;
        uint256 supply = totalSupply();
        
        require(supply + quantity <= maxSupply, "Exceeds max supply");
        require(quantity > 0, "No recipients provided");
        
        uint256 startTokenId = supply + 1;
        
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(recipients[i], startTokenId + i);
        }
        
        emit BatchAirdropped(recipients, startTokenId, quantity);
        
        return startTokenId + quantity - 1;
    }
    
    // Set base URI for metadata
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    
    // Base URI for all tokens
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    // Token URI implementation
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }
    
    // Set royalty info
    function setRoyaltyInfo(address _receiver, uint96 _percentage) external onlyOwner {
        require(_percentage <= 10000, "Percentage cannot exceed 100%");
        royaltyReceiver = _receiver;
        royaltyPercentage = _percentage;
    }
    
    // Implementation of IERC2981 royaltyInfo
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Token does not exist");
        
        // Calculate royalty amount (percentage is in basis points, e.g. 500 = 5%)
        uint256 amount = (_salePrice * royaltyPercentage) / 10000;
        
        return (royaltyReceiver, amount);
    }
    
    // Withdraw function for any ETH mistakenly sent to the contract
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
    
    // Override supportsInterface to declare IERC2981 support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC2981).interfaceId || 
            super.supportsInterface(interfaceId);
    }
}
