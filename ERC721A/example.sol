// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract example is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxTPerW;
    uint32 public publicSaleStartTime;
    uint256 public mintlistPrice = 0.01 ether;
    uint256 public publicPrice = 0.01 ether;
    uint32 public publicKey;
    string private _baseTokenURI;
    mapping(address => uint256) public allowlist;

    constructor(uint256 maxtokenperwallet_, uint256 collectionSize_) 
    ERC721A("example", "ex", maxtokenperwallet_,collectionSize_) {
            maxTPerW = maxtokenperwallet_;
            require(maxTPerW <= collectionSize_,"larger collection size needed");
    }

    modifier CIU() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function allowlistMint() external payable CIU {
        uint256 price = uint256(mintlistPrice);
        require(price != 0, "allowlist sale has not begun yet");
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
    }

    function publicSaleMint(uint256 quantity, uint256 callerKey)external payable CIU{
        require(publicKey == callerKey,"called with incorrect public key");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxTPerW,"can not mint this many");
        _safeMint(msg.sender, quantity);
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)external onlyOwner{
        require(addresses.length == numSlots.length,"addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
        allowlist[addresses[i]] = numSlots[i];
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMintlistPrice(uint256 newmintPrice) public onlyOwner {
        require(newmintPrice >= 0, "Price should greater than zero");
        mintlistPrice = newmintPrice;
    }

    function setPublicPrice(uint256 newmintPrice) public onlyOwner {
        require(newmintPrice >= 0, "Price should greater than zero");
        publicPrice = newmintPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawAllMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
 
    function getOwnershipData(uint256 tokenId)external view returns (TokenOwnership memory){
        return ownershipOf(tokenId);
    }
}
