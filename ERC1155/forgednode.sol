// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./ERC721O.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface Noded is IERC1155 {
    function burn(address account, uint256 amount) external;
}

contract NFORGED is ERC721O, Ownable, ReentrancyGuard {
    Noded private _NODE;
    address NODE_ = 0x9A52780bA2a0E09cf129FCc582b891AAfD50610f;
    using Strings for uint256;
    uint256 public constant maxsupply = 100;
    uint256 public PublicMintPrice = 0 ether;
    uint256 public whitelistmintPrice = 0.01 ether;
    uint256 public maxMPerx = 5;
    uint256 public maxMPW = 10;
    uint32 public PublicMintStartTime;
    uint32 public ListMintStartTime;
    string public hriPrefix;
    string public uriPrefix;
    string public uriSuffix;
    
    bool public publicMintPaused = false;
    bool public listMintPaused = false;
    bool public revealed = false;

    mapping(address => uint256) public iswhitelist;
    mapping(address => uint256) public isfreelist;
    mapping(address => uint256) public mintedbalance;
    
    event ERC721OMinted(uint256 indexed tokenId, address indexed mintAddress);

    constructor() ERC721O("NFORGED", "NFD") {
        setUriSuffix(".json");
    }

    modifier CIU() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function WhiteListMint(uint256 numberOfTokens) external payable CIU nonReentrant {
        uint256 StartTime = uint256(ListMintStartTime);
        uint256 totalS = totalSupply();
        require(!listMintPaused, "Listmint is paused!");
        require(StartTime != 0 ,"Start time could not be 0!");
        require(StartTime <= block.timestamp,"Sale not started!");
        require(numberOfTokens <= iswhitelist[msg.sender], "No capacity for this address");
        require(totalS + numberOfTokens <= maxsupply, "Purchase would exceed max tokens");
        require(whitelistmintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        iswhitelist[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            safemint(_msgSender());
            mintedbalance[_msgSender()] += 1;
        }
    }

    function FreeListMint(uint256 numberOfTokens) external payable CIU nonReentrant {
        uint256 StartTime = uint256(ListMintStartTime);
        uint256 totalS = totalSupply();
        require(!listMintPaused, "Listmint is paused!");
        require(StartTime != 0 ,"Start time could not be 0!");
        require(StartTime <= block.timestamp,"Sale not started!");
        require(numberOfTokens <= isfreelist[msg.sender], "No capacity for this address");
        require(totalS + numberOfTokens <= maxsupply, "Purchase would exceed max tokens");
        require(msg.value == 0, "Ether value sent is not correct");

        isfreelist[msg.sender] -= numberOfTokens;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            safemint(_msgSender());
            mintedbalance[_msgSender()] += 1;
        }
    }

    function PublicMint(uint256 numberOfTokens) public payable CIU nonReentrant {
        _NODE = Noded(NODE_);
        require(mintedbalance[_msgSender()] + numberOfTokens <= maxMPW, "You will exceed max mint amount per wallet");
        require(_NODE.balanceOf(_msgSender(), 0) > 0, "Not enough Seeds");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _NODE.burn(_msgSender(), 1);
            safemint(_msgSender());
            mintedbalance[_msgSender()] += 1;
        }
    }

    function setWhiteList(address[] calldata addresses, uint256 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            iswhitelist[addresses[i]] = numAllowedToMint;
        }
    }

    function setFreeList(address[] calldata addresses, uint256 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            isfreelist[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint256) {
        return iswhitelist[addr];
    }

    function numAvailableToFreeMint(address addr) external view returns (uint256) {
        return isfreelist[addr];
    }

    function togglelistMintPaused() external onlyOwner {
        listMintPaused = !listMintPaused;
    }

    function togglepublicMintPaused() external onlyOwner {
        publicMintPaused = !publicMintPaused;
    }

    function togglerevealed() external onlyOwner {
        revealed = !revealed;
    }

    function setPublicMintStartTime(uint32 timestamp) external onlyOwner {
        PublicMintStartTime = timestamp;
    }

    function setListMintStartTime(uint32 timestamp) external onlyOwner {
        ListMintStartTime = timestamp;
    }

    function setMintPrice(uint256 newmintPrice) public onlyOwner {
        require(newmintPrice >= 0, "Price should greater than zero");
        PublicMintPrice = newmintPrice;
    }
    
    function setwhitelistmintPrice(uint256 newwlPrice) public onlyOwner {
        require(newwlPrice >= 0, "Price should greater than zero");
        whitelistmintPrice = newwlPrice;
    }
    function setmaxTPerx(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount should greater than zero");
        maxMPerx = amount;
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }
    
    function safemint(address mintAddress) private {
        uint256 supplyNow = totalSupply();
        require(supplyNow < maxsupply,"Not enough Supply");
        _safeMint(mintAddress, supplyNow);
        emit ERC721OMinted(supplyNow, mintAddress);

    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        
        if (revealed == false) {
            string memory hiddenBaseURI = _hiddenURI();
            return bytes(hiddenBaseURI).length > 0 ? string(abi.encodePacked(hiddenBaseURI, (_tokenId).toString(), uriSuffix)): "";
            }
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, (_tokenId).toString(), uriSuffix)): "";
        }
    
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setHriPrefix(string memory _hriPrefix) public onlyOwner {
        hriPrefix = _hriPrefix;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }

    function _hiddenURI() internal view virtual returns (string memory) {
        return hriPrefix;
    }
}