// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./PhygitalAssets.sol";

contract PhygitalMarketplace is ERC1155Holder, Ownable, ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
        uint256 amount;
        bool active;
    }

    PhygitalAssets public immutable phygitalAssets;
    mapping(uint256 => mapping(address => Listing)) public listings;
    mapping(address => bool) public acceptedCurrencies;

    event ItemListed(address indexed seller, uint256 indexed tokenId, uint256 amount, uint256 price);
    event ItemSold(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 totalPrice,
        address currency
    );
    event ItemRemoved(address indexed seller, uint256 indexed tokenId);
    //event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CurrencyAdded(address indexed currency);
    event CurrencyRemoved(address indexed currency);
    event ListingPriceChanged(address indexed seller, uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);

    error AmountMustBeGreaterThanZero();
    error PriceMustBeGreaterThanZero();
    error InsufficientTokenBalance();
    error ContractNotApproved();
    error ListingNotActive();
    error NotEnoughItemsAvailable();
    error IncorrectETHSent();
    error CurrencyNotAccepted();
    error InsufficientAllowance();
    error InsufficientContractBalance();
    error InvalidCurrencyAddress();
    error InvalidOwnerAddress();
    error InvalidNewOwnerAddress();
    error InvalidAddress();

    constructor(address _phygitalAssets, address _initialOwner) Ownable(_initialOwner) {
        if (_phygitalAssets == address(0)) revert InvalidCurrencyAddress();
        if (_initialOwner == address(0)) revert InvalidOwnerAddress();
        phygitalAssets = PhygitalAssets(_phygitalAssets);
    }

    function addCurrency(address currency) external onlyOwner {
        if (currency == address(0)) revert InvalidCurrencyAddress();
        acceptedCurrencies[currency] = true;
        emit CurrencyAdded(currency);
    }

    function removeCurrency(address currency) external onlyOwner {
        if (!acceptedCurrencies[currency]) revert CurrencyNotAccepted();
        acceptedCurrencies[currency] = false;
        emit CurrencyRemoved(currency);
    }

    function listItem(uint256 tokenId, uint256 amount, uint256 price) external nonReentrant {
        if (amount == 0) revert AmountMustBeGreaterThanZero();
        if (price == 0) revert PriceMustBeGreaterThanZero();
        if (phygitalAssets.balanceOf(msg.sender, tokenId) < amount) revert InsufficientTokenBalance();
        if (!phygitalAssets.isApprovedForAll(msg.sender, address(this))) revert ContractNotApproved();

        listings[tokenId][msg.sender] = Listing({seller: msg.sender, price: price, amount: amount, active: true});
        phygitalAssets.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        emit ItemListed(msg.sender, tokenId, amount, price);
    }

    function buyItemWithETH(uint256 tokenId, address seller, uint256 amount) external payable nonReentrant {
        Listing storage listing = listings[tokenId][seller];
        if (!listing.active) revert ListingNotActive();
        if (listing.amount < amount) revert NotEnoughItemsAvailable();
        uint256 totalPrice = listing.price * amount;
        if (msg.value != totalPrice) revert IncorrectETHSent();
        if (seller == address(0)) revert InvalidAddress();

        payable(seller).transfer(msg.value);
        phygitalAssets.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        emit ItemSold(msg.sender, seller, tokenId, amount, totalPrice, address(0));
    }

    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient contract balance");
        require(recipient != address(0), "Recipient cannot be the zero address");
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function buyItemWithERC20(uint256 tokenId, address seller, uint256 amount, address currency)
        external
        nonReentrant
    {
        if (!acceptedCurrencies[currency]) revert CurrencyNotAccepted();
        Listing storage listing = listings[tokenId][seller];
        if (!listing.active) revert ListingNotActive();
        if (listing.amount < amount) revert NotEnoughItemsAvailable();

        uint8 decimals = IERC20Metadata(currency).decimals();
        uint256 priceAdjusted = listing.price * (10 ** decimals);
        uint256 totalPrice = priceAdjusted * amount;

        if (IERC20(currency).allowance(msg.sender, address(this)) < totalPrice) revert InsufficientAllowance();
        IERC20(currency).transferFrom(msg.sender, seller, totalPrice);
        phygitalAssets.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.active = false;
        }

        emit ItemSold(msg.sender, seller, tokenId, amount, totalPrice, currency);
    }

    function removeListing(uint256 tokenId) external nonReentrant {
        Listing storage listing = listings[tokenId][msg.sender];
        if (!listing.active) revert ListingNotActive();
        if (phygitalAssets.balanceOf(address(this), tokenId) < listing.amount) revert InsufficientContractBalance();

        delete listings[tokenId][msg.sender];
        phygitalAssets.safeTransferFrom(address(this), msg.sender, tokenId, listing.amount, "");

        emit ItemRemoved(msg.sender, tokenId);
    }

    function changeListingPrice(uint256 tokenId, uint256 newPrice) external nonReentrant {
        Listing storage listing = listings[tokenId][msg.sender];
        if (!listing.active) revert ListingNotActive();
        emit ListingPriceChanged(msg.sender, tokenId, listing.price, newPrice);
        listing.price = newPrice;
    }
}
