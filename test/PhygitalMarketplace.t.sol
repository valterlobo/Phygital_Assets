// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PhygitalMarketplace.sol";
import "../src/PhygitalAssets.sol";

contract PhygitalMarketplaceTest is Test {
    PhygitalAssets phygitalAssets;
    PhygitalMarketplace marketplace;
    address owner = address(this);
    address seller = address(0x123);
    address buyer = address(0x456);

    uint256 tokenId;
    uint256 price = 1 ether;

    function setUp() public {
        // Deploy contrato de ativos e marketplace
        string memory name = "PhygitalAssets";
        string memory symbol = "PGA";
        string memory uri = "https://example.com/metadata/";
        phygitalAssets = new PhygitalAssets(owner, name, symbol, uri);
        marketplace = new PhygitalMarketplace(address(phygitalAssets), owner);

        // Criar ativo ERC-1155
        phygitalAssets.createAsset(10, "Arte NFT", "ipfs://nft", 10, true);
        tokenId = 0;

        // Transferir NFT para o seller
        phygitalAssets.mintAsset(tokenId, seller, 5);
        vm.prank(seller);
        phygitalAssets.setApprovalForAll(address(marketplace), true);
    }

    function testListItem() public {
        vm.prank(seller);
        marketplace.listItem(tokenId, 2, price);

        (address listedSeller, uint256 listedPrice, uint256 amount, bool active) = marketplace.listings(tokenId, seller);

        assertEq(listedSeller, seller);
        assertEq(listedPrice, price);
        assertEq(amount, 2);
        assertTrue(active);
    }

    function testRemoveListing() public {
        vm.prank(seller);
        marketplace.listItem(tokenId, 3, price);
        assertEq(phygitalAssets.balanceOf(seller, tokenId), 2);

        vm.prank(seller);
        marketplace.removeListing(tokenId);

        (,, uint256 remainingAmount, bool active) = marketplace.listings(tokenId, seller);

        assertEq(remainingAmount, 0);
        assertFalse(active);
        assertEq(phygitalAssets.balanceOf(seller, tokenId), 5);
        //console.log(phygitalAssets.balanceOf(seller, tokenId));
        //console.log(phygitalAssets.balanceOf(address(marketplace), tokenId));
    }

    /*function testBuyItem() public {
        vm.prank(seller);
        marketplace.listItem(tokenId, 2, price);

        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        marketplace.buyItem{value: 2 ether}(tokenId, seller, 2);

        (,, uint256 remainingAmount, bool active) = marketplace.listings(tokenId, seller);

        assertEq(remainingAmount, 0);
        assertFalse(active);
        assertEq(phygitalAssets.balanceOf(buyer, tokenId), 2);
    }


    function test_Revert_BuyItemWithWrongPrice() public {
        vm.prank(seller);
        marketplace.listItem(tokenId, 1, price);

        vm.deal(buyer, 0.5 ether);
        vm.prank(buyer);
        vm.expectRevert("Incorrect ETH sent");
        marketplace.buyItem{value: 0.5 ether}(tokenId, seller, 1); // Deve falhar pois enviou ETH errado
    }

    */
}
