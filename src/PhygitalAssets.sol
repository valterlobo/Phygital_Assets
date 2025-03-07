// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./PhygitalAssetsStruct.sol";

contract PhygitalAssets is ERC1155, Ownable {
    string public name;
    string public symbol;
    string public uriAssets;

    mapping(uint256 => Asset) private assets;

    event AssetCreated(uint256 indexed tokenId, string name, uint256 maxSupply, bool supplyCapped);
    event AssetMinted(uint256 indexed tokenId, address indexed to, uint256 amount);
    event UriUpdated(uint256 indexed tokenId, string newUri);

    // Definição dos erros personalizados
    error AssetAlreadyExists(uint256 tokenId);
    error AssetDoesNotExist(uint256 tokenId);
    error MaxSupplyExceeded(uint256 tokenId, uint256 maxSupply, uint256 requestedAmount);
    error InvalidOwner();
    error EmptyName();
    error EmptySymbol();
    error AmountOverflow();
    error InvalidAmount();

    modifier activeAsset(uint256 id) {
        if (!_exists(id)) {
            revert AssetDoesNotExist(id);
        }
        _;
    }

    constructor(address initialOwner, string memory nameAssets, string memory symbolAssets, string memory uriContract)
        ERC1155("")
        Ownable(initialOwner)
    {
        if (initialOwner == address(0)) revert InvalidOwner();
        if (bytes(nameAssets).length == 0) revert EmptyName();
        if (bytes(symbolAssets).length == 0) revert EmptySymbol();
        name = nameAssets;
        symbol = symbolAssets;
        uriAssets = uriContract;
    }

    function createAsset(uint256 tokenId, string calldata nm, string calldata ur, uint256 maxSupply, bool supplyCapped)
        external
        onlyOwner
    {
        if (_exists(tokenId)) {
            revert AssetAlreadyExists(tokenId);
        }

        assets[tokenId] =
            Asset({id: tokenId, name: nm, totalSupply: 0, maxSupply: maxSupply, supplyCapped: supplyCapped, uri: ur});
        emit AssetCreated(tokenId, nm, maxSupply, supplyCapped);
    }

    function getAsset(uint256 tokenId) external view returns (Asset memory) {
        return assets[tokenId];
    }

    function mintAsset(uint256 tokenId, address to, uint256 amount) external onlyOwner activeAsset(tokenId) {

        if (amount == 0) revert InvalidAmount();

        if (assets[tokenId].supplyCapped) {
            if (assets[tokenId].totalSupply + amount > assets[tokenId].maxSupply) {
                revert MaxSupplyExceeded(tokenId, assets[tokenId].maxSupply, amount);
            }
        }

        assets[tokenId].totalSupply += amount;
        if (!assets[tokenId].supplyCapped) {
            assets[tokenId].maxSupply = assets[tokenId].totalSupply;
        }

        _mint(to, tokenId, amount, "");
        emit AssetMinted(tokenId, to, amount);
    }

    function uri(uint256 tokenId) public view override(ERC1155) activeAsset(tokenId) returns (string memory) {
        return assets[tokenId].uri;
    }

    function setUri(uint256 tokenId, string calldata newUri)
        external
        onlyOwner
        activeAsset(tokenId)
        returns (string memory)
    {
        assets[tokenId].uri = newUri;
        emit UriUpdated(tokenId, newUri);
        return assets[tokenId].uri;
    }

    function contractURI() public view returns (string memory) {
        return uriAssets;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _exists(uint256 id) internal view virtual returns (bool) {
        return (bytes(assets[id].name).length > 0);
    }
}
