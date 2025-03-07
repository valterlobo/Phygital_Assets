// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PhygitalAssets.sol";

contract PhygitalAssetsTest is Test {
    PhygitalAssets phygitalAssets;
    address owner = address(this);
    address user1 = address(0x123);

    function setUp() public {
        //address initialOwner, string memory nameAssets, string memory symbolAssets, string memory uriContract
        phygitalAssets =
            new PhygitalAssets(owner, "JOIAS COLECAO VERAO", "JOIAVERAO", "ipfs://dfdfdfdsfdsfdff/joiaverao.json");
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

    function testMintAssetWithinLimit() public {
        phygitalAssets.createAsset(2, "Colecionavel", "ipfs://metadata2", 50, true);
        phygitalAssets.mintAsset(2, user1, 10);

        Asset memory typeAsset = phygitalAssets.getAsset(2);
        assertEq(typeAsset.totalSupply, 10);
        assertEq(typeAsset.maxSupply, 50);
        console.log(typeAsset.maxSupply);
    }

    function test_Revert_MintExceedingSupply() public {
        //MintExceedingSupply
        vm.prank(owner);
        phygitalAssets.createAsset(1, "Escultura", "ipfs://metadata3", 5, true);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.MaxSupplyExceeded.selector, 1, 5, 6));
        phygitalAssets.mintAsset(1, user1, 6); // Deve falhar pois excede maxSupply
    }

    function testMintUnlimitedSupply() public {
        phygitalAssets.createAsset(1, "Obra Sem Limite", "ipfs://metadata4", 3, false);
        // mintAsset(uint256 _tokenId, address _to, uint256 _amount)
        phygitalAssets.mintAsset(1, user1, 30);

        Asset memory typeAsset = phygitalAssets.getAsset(1);
        assertEq(typeAsset.totalSupply, 30);
        assertEq(typeAsset.maxSupply, 30);
    }

    function testUriRetrieval() public {
        phygitalAssets.createAsset(1, "Quadro", "ipfs://metadata5", 20, true);
        string memory retrievedUri = phygitalAssets.uri(1);
        assertEq(retrievedUri, "ipfs://metadata5");
    }

    function test_Revert_MintNonExistentAsset() public {
        //Asset does not exist
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(PhygitalAssets.AssetDoesNotExist.selector, 99));
        phygitalAssets.mintAsset(99, user1, 1); // Deve falhar pois o ID 99 não existe
    }
}
