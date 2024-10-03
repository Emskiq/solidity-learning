// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {Tutorials} from "../src/Tutorials-1.sol";
import {Tutorials2} from "../src/Tutorials-2.sol";
import {Tutorials3} from "../src/Tutorials-3.sol";
import {Tutorials4} from "../src/Tutorials-4.sol";
import {A, B} from "../src/Tutorials-5.sol";
import {ArrayRemove} from "../src/ArrayRemove.sol";
import {IterableMap} from "../src/IterableMap.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {TodoList} from "../src/ToDoList.sol";

contract DeployTutorials1 is Script {
    function run() external {
        // Read environment variables
        string memory rpcUrl = vm.envString("RPC_URL");
        string memory etherscanApiKey = vm.envString("ETHERSCAN_API_KEY");

        uint privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        // Print environment variables for verification
        console.log("RPC_URL: ", rpcUrl);
        console.log("ETHERSCAN_API_KEY: ", etherscanApiKey);
        console.log("Account addr: ", account);

        // Start broadcasting the transaction
        vm.startBroadcast();
        // deploy contract
        Tutorials tutorial = new Tutorials();
        uint res = tutorial.sub(6, 5);
        (address caller, uint time, uint number) = tutorial.globalVar();
        vm.stopBroadcast();

        // Print contract state variables for verification
        console.logUint(tutorial.minUint());
        console.logUint(tutorial.maxUint());

        console.logInt(tutorial.minInt());
        console.logInt(tutorial.maxInt());

        console.log("Res from sub: ", res);

        console.log("Res from global vars.caller: ", caller);
        console.log("Res from global vars.time: ", time);
        console.log("Res from global vars.num: ", number);
    }
}

contract DeployTutorials2 is Script {
    function run() external {

        // Start broadcasting the transaction
        vm.startBroadcast();
        // deploy contract
        Tutorials2 tutorial = new Tutorials2();
        tutorial.setPause(false);
        tutorial.inc();
        tutorial.inc();
        tutorial.dec();
        // tutorial.setPause(true);
        tutorial.dec();
        tutorial.setPause(false);
        tutorial.foooo(69);
        vm.stopBroadcast();

        // Print contract state variables for verification
        console.log(tutorial.b());
        console.logUint(tutorial.ui());
        console.logInt(tutorial.i());
        console.log(tutorial.a());
        console.logBytes32(tutorial.b32());
        console.logUint(tutorial.count());
    }
}

// Deploy script for all the tutorials till Mapping pbly
contract DeployTutorials3 is Script {
    function run() external {
        vm.startBroadcast();

        // Tutorials3 tutorial = new Tutorials3();
        // tutorial.examples();

        ArrayRemove customArr = new ArrayRemove();
        customArr.push(1);
        customArr.push(2);
        customArr.push(3);
        customArr.push(4);
        customArr.push(5);

        customArr.remove(2);
        // customArr.remove(4); // revert state

        vm.stopBroadcast();

        uint length = customArr.arrLength();
        for (uint i = 0; i < length; i++) {
            console.log(customArr.arr(i));
        }

    }
}

// Deploy script for all the tutorials till Mapping pbly
contract DeployIterableMap is Script {
    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);

        vm.startBroadcast();

        IterableMap myMap = new IterableMap();
        myMap.add_balance_for(account, 69);
        myMap.add_balance_for(address(0), 420);

        uint mapLength = myMap.length();

        vm.stopBroadcast();

        // iterating over the map
        for (uint i = 0; i < mapLength; i++) {
            address addr = myMap.arr(i);
            uint balance = myMap.balances(addr);
            console.log("\nAddress:", addr, " Balance:", balance);
        }
    }
}

contract DeployTutorials4 is Script {
    function run() external {
        // Start deploying
        vm.startBroadcast();

        Tutorials4 tut = new Tutorials4();
        tut.initializeCarsArray();

        tut.setStatus(Tutorials4.Status.Completed);
        console.log("Contact status: ", uint(tut.getStatus()));

        tut.cancelContractStatus();

        uint[] memory returnArray = tut.examplesWithStorages(new uint[](2), "EMSKIQQQQ");

        // Set up expectEmit for Message event
        address recipient = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;
        string memory message = "Hello!";
        vm.expectEmit(true, true, false, true);
        emit Tutorials4.Message(msg.sender, recipient, message);

        // Call sendMessage to emit Message event
        tut.sendMessage(recipient, message);

        vm.stopBroadcast();
        // Stop deploying

        uint length = tut.carsLength();
        for (uint i = 0; i < length; i++) {
            (string memory model, uint year, address owner) = tut.cars(i);
            console.log("Car Model:", model);
            console.log("Car Year:", year);
            console.log("Car Owner:", owner);
        }

        console.log("Contact status in the end: ", uint(tut.getStatus()));


        for (uint i = 0; i < returnArray.length; i++) {
            console.log("return array element:", returnArray[i]);
        }
    }
}

contract DeploySimpleStorage is Script {
    function run() external {
        // Start deploying
        vm.startBroadcast();

        SimpleStorage ss = new SimpleStorage();

        ss.set("EMSKIQ");

        string memory storedText = ss.get();

        vm.stopBroadcast();
        // Stop deploying

        console.log("Stored text: ", storedText);

    }
}

contract DeployTodoList is Script {
    function run() external {
        // Start deploying
        vm.startBroadcast();

        TodoList todo = new TodoList();

        todo.create("Obsthaka");
        todo.create("EMskiq");
        todo.create("Trenka");

        todo.complete(2);

        vm.stopBroadcast();
        // Stop deploying
    }
}

contract DeployTutorials5 is Script {
    function run() external {
        // Start deploying
        vm.startBroadcast();

        B bContract = new B();
        string memory foo = bContract.foo();
        string memory bar = bContract.bar();
        string memory baz = bContract.baz();

        // Stop deploying
        vm.stopBroadcast();

        console.log("Text returned foo: ", foo);
        console.log("Text returned bar: ", bar);
        console.log("Text returned baz: ", baz);
    }
}
