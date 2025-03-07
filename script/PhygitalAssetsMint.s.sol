// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {PhygitalAssets} from "../src/PhygitalAssets.sol";

contract PhygitalAssetsMintScript is Script {
    function setUp() public {}

    function run() public {
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(ownerPrivateKey);
        address assetsContract = vm.envAddress("MINT_CONTRACT");
        PhygitalAssets phygitalAssets = PhygitalAssets(payable(assetsContract));
        console.log(address(phygitalAssets));

        phygitalAssets.createAsset(
            100,
            "Anel Sol Dourado #0",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/100.json",
            10,
            true
        );

        phygitalAssets.createAsset(
            1, "Anel Sol Dourado", "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/1.json", 10, true
        );
        phygitalAssets.createAsset(
            2,
            unicode"Colar Maré Prateada",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/2.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            3,
            "Pulseira Brisa Leve",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/3.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            4,
            unicode"Brinco Pôr do Sol",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/4.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            5,
            "Tornozeleira Areia Dourada",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/5.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            6,
            "Pingente Estrela do Mar",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/6.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            7,
            "Bracelete Oceano Azul",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/7.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            8,
            unicode"Aliança do Horizonte",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/8.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            9,
            "Broche Concha Dourada",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/9.json",
            100,
            true
        );
        phygitalAssets.createAsset(
            10,
            "Cinto de Corrente Marinha",
            "ipfs://bafybeiaalsgsj6xdu7fgf3lasyaftgudn2fbnglj4d6cyaynvfjvrevvta/10.json",
            100,
            true
        );

        /*uint256 id;
    string name;
    uint256 totalSupply;
    uint256 maxSupply;
    bool supplyCapped;
    string uri;*/

        //function mintAsset(uint256 _tokenId, address _to, uint256 _amount)

        phygitalAssets.mintAsset(1, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(2, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(3, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(4, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(5, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(6, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(7, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(8, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(9, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);
        phygitalAssets.mintAsset(10, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 4);

        //0x58b990d4B00d56DA17D3B3e6EDd44184b3FA3DD5
        phygitalAssets.mintAsset(8, address(0x58b990d4B00d56DA17D3B3e6EDd44184b3FA3DD5), 4);
        phygitalAssets.mintAsset(9, address(0x58b990d4B00d56DA17D3B3e6EDd44184b3FA3DD5), 4);
        phygitalAssets.mintAsset(10, address(0x58b990d4B00d56DA17D3B3e6EDd44184b3FA3DD5), 4);

        vm.stopBroadcast();
    }
}
