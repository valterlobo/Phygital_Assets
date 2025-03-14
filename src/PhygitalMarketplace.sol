// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./PhygitalAssets.sol";

contract PhygitalMarketplace is ERC1155Holder, Ownable, ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
        uint256 amount;
        bool active;
    }

    PhygitalAssets public immutable phygitalAssets;
    mapping(uint256 => mapping(address => Listing)) public listings; // tokenId -> seller -> Listing

    event ItemListed(address indexed seller, uint256 indexed tokenId, uint256 amount, uint256 price);
    event ItemSold(
        address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 amount, uint256 totalPrice
    );
    event ItemRemoved(address indexed seller, uint256 indexed tokenId);

    constructor(address _phygitalAssets, address _initialOwner) Ownable(_initialOwner) {
        phygitalAssets = PhygitalAssets(_phygitalAssets);
    }

    function listItem(uint256 tokenId, uint256 amount, uint256 price) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        //TODO COM APROVAÇÃO

        listings[tokenId][msg.sender] = Listing({seller: msg.sender, price: price, amount: amount, active: true});
        phygitalAssets.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        emit ItemListed(msg.sender, tokenId, amount, price);
    }

    function buyItem(uint256 tokenId, address seller, uint256 amount) external payable nonReentrant {
        Listing storage listing = listings[tokenId][seller];

        //corrigir o seller não colocar como parametro ??????

        require(listing.active, "Listing not active");
        require(listing.amount >= amount, "Not enough items available");
        require(msg.value == listing.price * amount, "Incorrect ETH sent");

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        payable(seller).transfer(msg.value);
        phygitalAssets.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        emit ItemSold(msg.sender, seller, tokenId, amount, msg.value);
    }

    function removeListing(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId][msg.sender];
        require(listing.active, "Listing not active");

        delete listings[tokenId][msg.sender];
        phygitalAssets.safeTransferFrom(address(this), msg.sender, tokenId, listing.amount, "");

        emit ItemRemoved(msg.sender, tokenId);
    }
}
