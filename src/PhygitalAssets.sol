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

    function createAsset(string memory nm, string calldata ur, uint256 maxSupply, bool supplyCapped)
        external
        onlyOwner
    {
        uint256 tokenId = nextTokenId++;
        assets[tokenId] = Asset({
            id: tokenId,
            name: nm,
            totalSupply: 0,
            maxSupply: maxSupply,
            supplyCapped: supplyCapped,
            uri: ur
        });
        emit AssetCreated(tokenId, nm, maxSupply, supplyCapped);
    }

    function mintAsset(uint256 tokenId, address to, uint256 amount) external onlyOwner {
        require(bytes(assets[tokenId].name).length > 0, "Asset does not exist");

        if (assets[tokenId].supplyCapped) {
            require(assets[tokenId].totalSupply + amount <= assets[tokenId].maxSupply, "Max supply reached");
        }

        assets[tokenId].totalSupply += amount;
        if (!assets[tokenId].supplyCapped) {
            assets[tokenId].maxSupply = assets[tokenId].totalSupply;
        }

        _mint(to, tokenId, amount, "");
        emit AssetMinted(tokenId, to, amount);
    }

    function uri(uint256 tokenId) public view override(ERC1155) returns (string memory) {
        require(bytes(assets[tokenId].name).length > 0, "Asset does not exist");
        return assets[tokenId].uri;
    }

    function setUri(uint256 tokenId, string memory newUri) external onlyOwner returns (string memory) {
        require(bytes(assets[tokenId].name).length > 0, "Asset does not exist");
        assets[tokenId].uri = newUri;
        return assets[tokenId].uri;
    }
}
