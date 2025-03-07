// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PhygitalAssets} from "../src/PhygitalAssets.sol";

contract PhygitalAssetsDeployScript is Script {
    PhygitalAssets public phygitalAssets;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address initialOwner = vm.envAddress("OWNER");
        phygitalAssets = new PhygitalAssets(
            initialOwner, "JOIAS COLECAO VERAO", "JOIAVERAO", "ipfs://dfdfdfdsfdsfdff/joiaverao.json"
        );
        vm.stopBroadcast();
    }
}
