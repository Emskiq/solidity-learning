// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageChild is SimpleStorage {
    function store (uint256 favNum) public override {
        myFavNumber = 2 * favNum;
    }
}
