// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Noded is ERC1155, ERC1155Burnable, ERC1155Supply, ERC2981,Ownable, AccessControl{

    uint256 public constant NODE = 0;

    uint256 public constant NODE2 = 1;

    uint256 public constant NODE3 = 2;

    uint256 public maxSupply;

    mapping(address => uint256) private _count;
    mapping(uint256 => uint256) private _collection;
    mapping(uint256 => uint256) private _collectionlimit;
    

    string private _name;

    string private _symbol;

    address private _connectionaddress;

    bytes32 private _merkleRoot;

    uint256 private _price;

    bool private _active;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 price_,
        string memory uri_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _price = price_;
        _active = false;
    }

    function redeem(uint256 amount) external payable {
        _collectionlimit[0] = 2;
        _collectionlimit[1] = 3;
        _collectionlimit[2] = 5;
        
        uint256 tokenid = randomNum();

        if (_collection[tokenid] >= _collectionlimit[tokenid]) {
            tokenid = 0;
            require(_collection[tokenid] < _collectionlimit[tokenid], "collection full"); 
        } if (_collection[tokenid] >= _collectionlimit[tokenid]){
            tokenid = 1;
            require(_collection[tokenid] < _collectionlimit[tokenid], "collection full"); 
        } if (_collection[tokenid] >= _collectionlimit[tokenid]){
            tokenid = 2;
            require(_collection[tokenid] < _collectionlimit[tokenid], "collection full"); 
        }

        require(_collection[tokenid] < _collectionlimit[tokenid], "collection full"); 
        require(_active, "Not active");
        require(amount > 0, "Invalid amount");
        require(_price * amount <= msg.value, "Value incorrect");
        require(_count[_msgSender()] + amount <= 10, "Exceeded max per wallet");
        require(totalSupply(NODE) + amount <= maxSupply, "Exceeded max supply");
        
        _count[_msgSender()] = _count[_msgSender()] + amount;
        _collection[tokenid]+=1;
        _mint(_msgSender(), tokenid, amount,"");
    }


    function mint(address account, uint256 amount) external onlyOwner {
        require(totalSupply(NODE) + amount <= maxSupply, "Exceeded max supply");

        _mint(account, NODE, amount, "");
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;
    }

    function setActive(bool newActive) external onlyOwner {
        _active = newActive;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setURI(string memory newURI)external onlyOwner{
        _setURI(newURI);
    }


    function setconnectionaddress(address newconnectionaddress)
        external
        onlyOwner{
        _connectionaddress = newconnectionaddress;
    }

    function burn(address account, uint256 amount) external {
        require(_msgSender() == _connectionaddress, "Invalid address");

        _burn(account, NODE, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function randomNum() public view returns (uint) {
        uint randNonce = 0;
        randNonce++;
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 3;
        return random;
    } 

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function active() external view returns (bool) {
        return _active;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}