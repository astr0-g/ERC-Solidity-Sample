// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721Optimized.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract ERC721 is ERC721Optimized, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = "";
    string public hiddenMetadataUri;

    uint256 public mintPrice = 0.1 ether;
    uint256 public constant maxsupply = 10;
    uint256 public fMsupply = 5;
    uint256 public maxMPerx = 5;
    uint256 public maxFMPerx = 5;
    uint256 public maxFMPerW = 10;

    bool public publicMintPaused = true;
    bool public revealed = false;

    mapping(address => uint256) public balance;

    event ERC721Minted(address indexed mintAddress, uint256 indexed tokenId);

    constructor() ERC721Optimized("ERC721", "721") {
        setHiddenMetadataUri("");
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
            }

            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, (_tokenId-1).toString(), uriSuffix))
                : "";
        }

    function PublicMint(uint256 numberOfTokens) public payable nonReentrant {
        require(!publicMintPaused, "Public mint is paused!");
        uint256 supply = totalSupply();
        if (supply < fMsupply) {
            require(numberOfTokens <= maxFMPerx, "Too many tokens per transaction");
            require(balance[_msgSender()] + numberOfTokens <= maxFMPerW, "You will exceed max amount per wallet");
        } else {
            require(numberOfTokens <= maxMPerx, "Too many tokens per transaction");
        }
        require((supply + numberOfTokens) <= maxsupply, "Purchase would exceed max supply");
        require(getTotalMintPrice(numberOfTokens) == msg.value, "Incorrect Ether amount sent");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSingle(_msgSender());
            balance[_msgSender()] += 1;
        }
    }

    function getCurrentMintPrice() public view returns (uint256) {
        return totalSupply() >= fMsupply ? mintPrice : 0;
    }

    function getMintPriceForToken(uint256 tokenId) public view returns (uint256) {
        return tokenId >= fMsupply ? mintPrice : 0;
    }

    function getTotalMintPrice(uint256 numberOfTokens) public view returns (uint256) {
        require(numberOfTokens > 0, "Number should greater than zero");
        uint256 tokenId = totalSupply();
        uint256 end = tokenId + numberOfTokens;
        require(end <= maxsupply, "Exceeded maxsupply");
        if (end <= fMsupply) {
            return 0;
        } else {
            uint256 totalPrice = 0;
            for (; tokenId < end; ++tokenId) {
                totalPrice = totalPrice + getMintPriceForToken(tokenId);
            }
            return totalPrice;
        }
    }

    function togglepublicMintPaused() external onlyOwner {
        publicMintPaused = !publicMintPaused;
    }

    function togglerevealed() external onlyOwner {
        revealed = !revealed;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "Price should greater than zero");
        mintPrice = newPrice;
    }

    function setmaxTPerx(uint256 amount) public onlyOwner {
        require(amount > 0, "Amount should greater than zero");
        maxMPerx = amount;
    }

    function setfMsupply(uint256 amount) public onlyOwner {
        require(amount >= 0, "Amount should greater than zero");
        fMsupply = amount;
    }

    function setmaxFMPerx(uint256 amount) public onlyOwner {
        require(amount >= 0, "Amount should greater than zero");
        maxFMPerx = amount;
    }

    function setmaxFMPerW(uint256 amount) public onlyOwner {
        require(amount >= 0, "Amount should greater than zero");
        maxFMPerW = amount;
    }

    function withdrawTo(uint256 amount, address payable to) public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");
        Address.sendValue(to, amount);
    }


    function _mintSingle(address mintAddress) private {
        uint256 mintIndex = totalSupply();
        if (mintIndex < maxsupply) {
            _safeMint(mintAddress, mintIndex);
            emit ERC721Minted(mintAddress, mintIndex);
        }
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return uriPrefix;
    }
}