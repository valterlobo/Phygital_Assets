// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct Asset {
    uint256 id;
    string name;
    uint256 totalSupply;
    uint256 maxSupply;
    bool supplyCapped;
    string uri;
}
