// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract SimpleStorageScript is Script {

    function run() public returns(SimpleStorage) {
        vm.startBroadcast();

        // Deploy the contract
        SimpleStorage simpleStorage = new SimpleStorage();
        console.log("SimpleStorage deployed at:", address(simpleStorage));

        // Store a new favorite number
        simpleStorage.store(42);
        console.log("Stored number:", simpleStorage.retrieve());

        // Add a new person to the friends array
        simpleStorage.addPerson(100, "Alice");
        console.log("Added Alice with favorite number 100");

        // Retrieve and log stored values
        uint256 favNum = simpleStorage.retrieve();
        console.log("Retrieved number:", favNum);

        // Get Alice's favorite number from the mapping
        uint256 aliceFavNumber = simpleStorage.nameToFavNum("Alice");
        console.log("Alice's favorite number:", aliceFavNumber);

        // Person[] memory fr = simpleStorage.retrieveFriends();

        vm.stopBroadcast();
        return simpleStorage;
    }
}
