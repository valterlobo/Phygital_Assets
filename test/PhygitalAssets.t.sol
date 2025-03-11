// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PhygitalAssets.sol";

contract PhygitalAssetsTest is Test {
    PhygitalAssets phygitalAssets;
    address owner = address(this);
    address user1 = address(0x123);
    address user = address(0x456);

    function setUp() public {
        //address initialOwner, string memory nameAssets, string memory symbolAssets, string memory uriContract
        phygitalAssets = new PhygitalAssets(owner, "JOIAS COLECAO VERAO", "JOIAVERAO", "https://example.com/metadata/");
    }

    function testCreateAsset() public {
        //createAsset(string memory _name, string calldata _uri, uint256 _maxSupply, bool _supplyCapped)
        phygitalAssets.createAsset(1, "Arte Exclusiva", "ipfs://metadata1", 100, true);

        Asset memory typeAsset = phygitalAssets.getAsset(1);

        assertEq(typeAsset.id, 1);
        assertEq(typeAsset.name, "Arte Exclusiva");
        assertEq(typeAsset.maxSupply, 100);
        assertEq(typeAsset.supplyCapped, true);
        assertEq(typeAsset.uri, "ipfs://metadata1");
    }

    // Test creating an asset with an existing tokenId
    function testCreateAssetWithExistingId() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset1", "https://example.com/asset1", 100, true);

        // Attempt to create another asset with the same tokenId
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.AssetAlreadyExists.selector, 1));
        phygitalAssets.createAsset(1, "Asset2", "https://example.com/asset2", 200, true);
    }

    function testMintAssetWithinLimit() public {
        phygitalAssets.createAsset(2, "Colecionavel", "ipfs://metadata2", 50, true);
        phygitalAssets.mintAsset(2, user1, 10);

        Asset memory typeAsset = phygitalAssets.getAsset(2);
        assertEq(typeAsset.totalSupply, 10);
        assertEq(typeAsset.maxSupply, 50);
        console.log(typeAsset.maxSupply);
    }

    // Test minting with invalid amount (zero)
    function testMintWithInvalidAmount() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset1", "https://example.com/asset1", 100, true);

        // Attempt to mint zero tokens
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.InvalidAmount.selector));
        phygitalAssets.mintAsset(1, user, 0);
    }

    function test_Revert_MintExceedingSupply() public {
        //MintExceedingSupply
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Escultura", "ipfs://metadata3", 5, true);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.MaxSupplyExceeded.selector, 1, 5, 6));
        phygitalAssets.mintAsset(1, user1, 6); // Deve falhar pois excede maxSupply
    }

    // Test minting beyond maxSupply
    function testMintBeyondMaxSupply() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset1", "https://example.com/asset1", 100, true);

        vm.prank(owner);
        phygitalAssets.mintAsset(1, user, 100); // Mint up to maxSupply

        // Attempt to mint beyond maxSupply
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.MaxSupplyExceeded.selector, 1, 100, 1));
        phygitalAssets.mintAsset(1, user, 1);
    }

    function testMintUnlimitedSupply() public {
        phygitalAssets.createAsset(1, "Obra Sem Limite", "ipfs://metadata4", 3, false);
        // mintAsset(uint256 _tokenId, address _to, uint256 _amount)
        phygitalAssets.mintAsset(1, user1, 30);

        Asset memory typeAsset = phygitalAssets.getAsset(1);
        assertEq(typeAsset.totalSupply, 30);
        assertEq(typeAsset.maxSupply, 30);
    }

    // Test minting with uncapped supply
    function testMintWithUncappedSupply() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset1", "https://example.com/asset1", 0, false);

        vm.prank(owner);
        phygitalAssets.mintAsset(1, user, 1000);

        // Check the balance of the user
        assertEq(phygitalAssets.balanceOf(user, 1), 1000);

        // Check the total supply of the asset
        Asset memory asset = phygitalAssets.getAsset(1);
        assertEq(asset.totalSupply, 1000);
    }

    function testUriRetrieval() public {
        phygitalAssets.createAsset(1, "Quadro", "ipfs://metadata5", 20, true);
        string memory retrievedUri = phygitalAssets.uri(1);
        assertEq(retrievedUri, "ipfs://metadata5");
    }

    // Test updating the URI of an asset
    function testUpdateUri() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset1", "https://example.com/asset1", 100, true);

        vm.prank(owner);
        phygitalAssets.setUri(1, "https://example.com/new-uri");

        // Check if the URI was updated
        assertEq(phygitalAssets.uri(1), "https://example.com/new-uri");
    }

    // Test contractURI
    function testContractURI() public view {
        assertEq(phygitalAssets.contractURI(), "https://example.com/metadata/");
    }

    function test_Revert_MintNonExistentAsset() public {
        //Asset does not exist
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.AssetDoesNotExist.selector, 99));
        phygitalAssets.mintAsset(99, user1, 1); // Deve falhar pois o ID 99 não existe
    }

    //Supports interface test
    // Test supportsInterface for ERC1155
    function testSupportsInterfaceERC1155() public view  {
        // ERC1155 interface ID
        bytes4 interfaceIdERC1155 = type(IERC1155).interfaceId;
        assertTrue(phygitalAssets.supportsInterface(interfaceIdERC1155));
    }

    // Test supportsInterface for ERC1155MetadataURI
    function testSupportsInterfaceERC1155MetadataURI() public {
        // ERC1155MetadataURI interface ID
        bytes4 interfaceIdERC1155MetadataURI = type(IERC1155MetadataURI).interfaceId;
        assertTrue(phygitalAssets.supportsInterface(interfaceIdERC1155MetadataURI));
    }

    // Test supportsInterface for an unsupported interface
    function testSupportsInterfaceUnsupported() public {
        // Random unsupported interface ID
        bytes4 unsupportedInterfaceId = 0xffffffff;
        assertFalse(phygitalAssets.supportsInterface(unsupportedInterfaceId));
    }

    //test AssetDoesNotExist
    // Test the activeAsset modifier when the asset exists
    function testActiveAssetWhenAssetExists() public {
        // Create an asset with tokenId = 1
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset1", "https://example.com/asset1", 100, true);

        // Try to mint tokens for the existing asset (should not revert)
        vm.prank(owner);
        phygitalAssets.mintAsset(1, user, 10);

        // Check if the tokens were minted successfully
        assertEq(phygitalAssets.balanceOf(user, 1), 10);
    }

    // Test the activeAsset modifier when the asset does not exist
    function testActiveAssetWhenAssetDoesNotExist() public {
        // Try to mint tokens for a non-existent asset (should revert)
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.AssetDoesNotExist.selector, 1));
        phygitalAssets.mintAsset(1, user, 10);
    }

    // Test the activeAsset modifier with multiple assets
    function testActiveAssetWithMultipleAssets() public {
        // Create two assets with tokenId = 1 and tokenId = 2
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset1", "https://example.com/asset1", 100, true);
        vm.prank(owner);
        phygitalAssets.createAsset(2, "Asset2", "https://example.com/asset2", 200, true);

        // Mint tokens for the first asset (should not revert)
        vm.prank(owner);
        phygitalAssets.mintAsset(1, user, 10);

        // Mint tokens for the second asset (should not revert)
        vm.prank(owner);
        phygitalAssets.mintAsset(2, user, 20);

        // Check balances
        assertEq(phygitalAssets.balanceOf(user, 1), 10);
        assertEq(phygitalAssets.balanceOf(user, 2), 20);

        // Try to mint tokens for a non-existent asset (should revert)
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.AssetDoesNotExist.selector, 3));
        phygitalAssets.mintAsset(3, user, 30);
    }
}
