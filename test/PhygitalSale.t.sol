// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/PhygitalSale.sol";
import "../src/PhygitalAssets.sol";

contract PhygitalSaleTest is Test {
    PhygitalAssets phygitalAssets;
    PhygitalSale phygitalSale;
    address owner = address(1);
    address seller = address(2);
    address buyer = address(3);
    address feeRecipient = address(4);

    uint256 feePercentage = 500; // 5%

    function setUp() public {
        vm.startPrank(owner);
        phygitalAssets = new PhygitalAssets(owner, "JOIAS COLECAO VERAO", "JOIAVERAO", "https://example.com/metadata/");

        phygitalSale = new PhygitalSale(address(phygitalAssets), feeRecipient, feePercentage, owner);
        phygitalAssets.grantMinterRole(address(phygitalSale));
        phygitalAssets.createAsset(1, "Arte Exclusiva", "ipfs://metadata1", 100, true);
        vm.stopPrank();
    }

    function testCreateSale() public {
        vm.startPrank(owner);
        phygitalAssets.setApprovalForAll(address(phygitalSale), true);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        tokenIds[0] = 1;
        amounts[0] = 10;
        uint256 price = 1 ether;

        uint256 saleId = phygitalSale.createSale(owner, tokenIds, amounts, price, 104);
        (, address paymentReceiver, uint256 salePrice, bool active,) = phygitalSale.sales(saleId);
        assertEq(paymentReceiver, owner);
        assertEq(salePrice, price);
        assertTrue(active);
        vm.stopPrank();
    }

    function testPurchase() public {
        vm.startPrank(owner);
        phygitalAssets.setApprovalForAll(address(phygitalSale), true);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        tokenIds[0] = 1;
        amounts[0] = 10;
        uint256 price = 1 ether;
        uint256 saleId = phygitalSale.createSale(seller, tokenIds, amounts, price, 102);
        vm.stopPrank();

        vm.deal(buyer, 2 ether);
        vm.startPrank(buyer);
        phygitalSale.purchase{value: price}(saleId);
        vm.stopPrank();
    }

    function testCancelSale() public {
        vm.startPrank(owner);
        phygitalAssets.setApprovalForAll(address(phygitalSale), true);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        tokenIds[0] = 1;
        amounts[0] = 10;
        uint256 price = 1 ether;
        uint256 saleId = phygitalSale.createSale(seller, tokenIds, amounts, price, 100);
        phygitalSale.cancelSale(saleId);
        (,,, bool active,) = phygitalSale.sales(saleId);
        assertFalse(active);
        vm.stopPrank();
    }

    function testPurchaseWithoutFunds() public {
        vm.startPrank(owner);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        tokenIds[0] = 1;
        amounts[0] = 10;
        uint256 price = 1 ether;
        uint256 saleId = phygitalSale.createSale(seller, tokenIds, amounts, price, 1);
        vm.stopPrank();

        vm.startPrank(buyer);
        vm.expectRevert(PhygitalSale.InsufficientPayment.selector);
        phygitalSale.purchase{value: 0.0 ether}(saleId);
        vm.stopPrank();
    }

    function testPurchaseNonExistentSale() public {
        vm.deal(buyer, 2 ether);
        vm.startPrank(buyer);
        vm.expectRevert(PhygitalSale.SaleNotActive.selector);
        phygitalSale.purchase{value: 1 ether}(12345);
        vm.stopPrank();
    }
}
