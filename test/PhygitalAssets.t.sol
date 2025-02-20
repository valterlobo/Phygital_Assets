// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PhygitalAssets.sol";

contract PhygitalAssetsTest is Test {
    PhygitalAssets phygitalAssets;
    address owner = address(this);
    address user1 = address(0x123);

    function setUp() public {
        phygitalAssets = new PhygitalAssets(owner);
    }

    function testCreateAsset() public {
        //createAsset(string memory _name, string calldata _uri, uint256 _maxSupply, bool _supplyCapped)
        phygitalAssets.createAsset("Arte Exclusiva", "ipfs://metadata1", 100, true);

        (uint256 id, string memory name,, uint256 maxSupply, bool supplyCapped, string memory uri) =
            phygitalAssets.assets(0);

        assertEq(id, 0);
        assertEq(name, "Arte Exclusiva");
        assertEq(maxSupply, 100);
        assertEq(supplyCapped, true);
        assertEq(uri, "ipfs://metadata1");
    }

    function testMintAssetWithinLimit() public {
        phygitalAssets.createAsset("Colecionavel", "ipfs://metadata2", 50, true);
        phygitalAssets.mintAsset(0, user1, 10);

        (,, uint256 totalSupply, uint256 maxSupply,,) = phygitalAssets.assets(0);
        assertEq(totalSupply, 10);
        assertEq(maxSupply, 50);
    }

    function test_Revert_MintExceedingSupply() public {
        //MintExceedingSupply
        vm.prank(owner);
        phygitalAssets.createAsset("Escultura", "ipfs://metadata3", 5, true);
        vm.expectRevert("Max supply reached");
        phygitalAssets.mintAsset(0, user1, 6); // Deve falhar pois excede maxSupply
    }

    function testMintUnlimitedSupply() public {
        phygitalAssets.createAsset("Obra Sem Limite", "ipfs://metadata4", 0, false);
        // mintAsset(uint256 _tokenId, address _to, uint256 _amount)
        phygitalAssets.mintAsset(0, user1, 30);

        (,, uint256 totalSupply, uint256 maxSupply,,) = phygitalAssets.assets(0);
        assertEq(totalSupply, 30);
        assertEq(maxSupply, 30);
    }

    function testUriRetrieval() public {
        phygitalAssets.createAsset("Quadro", "ipfs://metadata5", 20, true);
        string memory retrievedUri = phygitalAssets.uri(0);
        assertEq(retrievedUri, "ipfs://metadata5");
    }

    function test_Revert_MintNonExistentAsset() public {
        //Asset does not exist
        vm.prank(owner);
        vm.expectRevert("Asset does not exist");
        phygitalAssets.mintAsset(99, user1, 1); // Deve falhar pois o ID 99 não existe
    }
}
