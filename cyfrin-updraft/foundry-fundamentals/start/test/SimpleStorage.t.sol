// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage public simpleStorage;

    function setUp() public {
        simpleStorage = new SimpleStorage();
    }


    function testFuzz_SetFavNumber(uint256 x) public {
        simpleStorage.store(x);
        assertEq(simpleStorage.retrieve(), x);
    }
}
