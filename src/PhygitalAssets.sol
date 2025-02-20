// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./PhygitalAssetsStruct.sol";

contract PhygitalAssets is ERC1155, Ownable {
    using Strings for uint256;

    mapping(uint256 => Asset) public assets;
    uint256 private nextTokenId;

    event AssetCreated(uint256 indexed tokenId, string name, uint256 maxSupply, bool supplyCapped);
    event AssetMinted(uint256 indexed tokenId, address indexed to, uint256 amount);

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    function createAsset(string memory _name, string calldata _uri, uint256 _maxSupply, bool _supplyCapped)
        external
        onlyOwner
    {
        uint256 tokenId = nextTokenId++;
        assets[tokenId] = Asset({
            id: tokenId,
            name: _name,
            totalSupply: 0,
            maxSupply: _maxSupply,
            supplyCapped: _supplyCapped,
            uri: _uri
        });
        emit AssetCreated(tokenId, _name, _maxSupply, _supplyCapped);
    }

    function mintAsset(uint256 _tokenId, address _to, uint256 _amount) external onlyOwner {
        require(bytes(assets[_tokenId].name).length > 0, "Asset does not exist");

        if (assets[_tokenId].supplyCapped) {
            require(assets[_tokenId].totalSupply + _amount <= assets[_tokenId].maxSupply, "Max supply reached");
        }

        assets[_tokenId].totalSupply += _amount;
        if (!assets[_tokenId].supplyCapped) {
            assets[_tokenId].maxSupply = assets[_tokenId].totalSupply;
        }

        _mint(_to, _tokenId, _amount, "");
        emit AssetMinted(_tokenId, _to, _amount);
    }

    function uri(uint256 _tokenId) public view override(ERC1155) returns (string memory) {
        require(bytes(assets[_tokenId].name).length > 0, "Asset does not exist");
        return assets[_tokenId].uri;
    }

    function setUri(uint256 _tokenId, string memory _newUri) external onlyOwner returns (string memory) {
        require(bytes(assets[_tokenId].name).length > 0, "Asset does not exist");
        assets[_tokenId].uri = _newUri;
        return assets[_tokenId].uri;
    }
}
