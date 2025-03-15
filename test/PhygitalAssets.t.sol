// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PhygitalAssets.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PhygitalAssetsTest is Test {
    PhygitalAssets phygitalAssets;
    address owner = address(this);
    address user1 = address(0x123);
    address user = address(0x456);

    function setUp() public {
        //address initialOwner, string memory nameAssets, string memory symbolAssets, string memory uriContract
        phygitalAssets = new PhygitalAssets(owner, "JOIAS COLECAO VERAO", "JOIAVERAO", "https://example.com/metadata/");
    }

    //test constructor

    // Test successful deployment with valid parameters
    function testConstructorSuccess() public {
        address ow = address(0x123);
        address zeroAddress = address(0);
        string memory name = "PhygitalAssets";
        string memory symbol = "PGA";
        string memory uri = "https://example.com/metadata/";
        vm.prank(owner);
        PhygitalAssets phygitalAssets1 = new PhygitalAssets(ow, name, symbol, uri);

        console.log("--------------------------------");
        console.log(phygitalAssets1.contractURI());

        // Check if the contract was initialized correctly
        assertEq(phygitalAssets1.owner(), ow);
        assertEq(phygitalAssets1.name(), name);
        assertEq(phygitalAssets1.symbol(), symbol);
        assertEq(phygitalAssets1.contractURI(), uri);
    }

    // Test deployment with zero address as owner
    function testConstructorWithZeroAddress() public {
        address zeroAddress = address(0);
        string memory name = "PhygitalAssets";
        string memory symbol = "PGA";
        string memory uri = "https://example.com/metadata/";
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, zeroAddress));
        new PhygitalAssets(zeroAddress, name, symbol, uri);
    }

    // Test deployment with empty name
    function testConstructorWithEmptyName() public {
        address ow = address(0x123);
        address zeroAddress = address(0);
        string memory name = "PhygitalAssets";
        string memory symbol = "PGA";
        string memory uri = "https://example.com/metadata/";

        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.EmptyName.selector));
        new PhygitalAssets(owner, "", symbol, uri);
    }

    // Test deployment with empty symbol
    function testConstructorWithEmptySymbol() public {
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.EmptySymbol.selector));
        address ow = address(0x123);
        address zeroAddress = address(0);
        string memory name = "PhygitalAssets";
        string memory symbol = "PGA";
        string memory uri = "https://example.com/metadata/";
        new PhygitalAssets(owner, name, "", uri);
    }

    // Test deployment with empty URI
    function testConstructorWithEmptyURI() public {
        address ow = address(0x123);
        address zeroAddress = address(0);
        string memory name = "PhygitalAssets";
        string memory symbol = "PGA";
        // Empty URI is allowed, so this should not revert
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.InvalidURI.selector));
        PhygitalAssets phygitalAssets2 = new PhygitalAssets(owner, name, symbol, "");
    }

    //
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
    function testSupportsInterfaceERC1155() public view {
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

    //Remove an asset with no minted tokens (success)
    function testRemoveAssetNoMintedTokens() public {
        // Create an asset
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset 1", "https://example.com/1", 1000, true);

        // Remove the asset
        vm.prank(owner);
        phygitalAssets.removeAsset(1);

        // Verify the asset no longer exists
        (bool exists,) = address(phygitalAssets).call(abi.encodeWithSignature("_exists(uint256)", 1));
        assertFalse(exists, "Asset should not exist after removal");
    }

    //Attempt to remove an asset with minted tokens (should fail)
    function testRemoveAssetWithMintedTokens() public {
        // Create an asset
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset 1", "https://example.com/1", 1000, true);

        // Mint some tokens
        vm.prank(owner);
        phygitalAssets.mintAsset(1, address(0x789), 10);

        // Attempt to remove the asset (should revert)
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.CannotRemoveAssetWithMintedTokens.selector, 1));
        phygitalAssets.removeAsset(1);
    }

    //Attempt to remove a non-existent asset (should fail)
    function testRemoveNonExistentAsset() public {
        // Attempt to remove an asset that doesn't exist (should revert)
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.AssetDoesNotExist.selector, 999));
        phygitalAssets.removeAsset(999);
    }

    //Attempt to remove an asset by a non-owner (should fail)
    function testRemoveAssetByNonOwner() public {
        // Create an asset
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset 1", "https://example.com/1", 1000, true);

        // Attempt to remove the asset by a non-owner (should revert)
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        phygitalAssets.removeAsset(1);
    }

    //Attempt to create an asset with an empty URI (should fail)
    function testCreateAssetWithEmptyURI() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.InvalidURI.selector));
        phygitalAssets.createAsset(1, "PhygitalAssets", "", 1000, true);
    }

    // Attempt to mint to the zero address (should fail)
    function testMintToZeroAddress() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset 1", "https://example.com/1", 1000, true);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.InvalidAddress.selector));
        phygitalAssets.mintAsset(1, address(0), 10);
    }

    //Attempt to set an empty URI (should fail)
    function testSetEmptyURI() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset 1", "https://example.com/1", 1000, true);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.InvalidURI.selector));
        phygitalAssets.setUri(1, "");
    }

    // Test 8: Mint multiple assets in a batch (success)
    function testMintAssetBatch() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset 1", "https://example.com/1", 1000, true);
        vm.prank(owner);
        phygitalAssets.createAsset(2, "Asset 2", "https://example.com/2", 1000, true);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        address to = address(0x123);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 20;

        vm.prank(owner);
        phygitalAssets.mintAssetBatch(tokenIds, to, amounts);

        // Verify balances
        assertEq(phygitalAssets.balanceOf(to, tokenIds[0]), 10);
        assertEq(phygitalAssets.balanceOf(to, tokenIds[1]), 20);
    }

    // Test 9: Attempt to mint with mismatched array lengths (should fail)
    function testMintAssetBatchArrayLengthMismatch() public {
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Asset 1", "https://example.com/1", 1000, true);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 10;

        address to = address(0x123);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.ArrayLengthMismatch.selector));
        phygitalAssets.mintAssetBatch(tokenIds, to, amounts);
    }
}
