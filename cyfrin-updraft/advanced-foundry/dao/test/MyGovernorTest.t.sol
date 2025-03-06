// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {MyGovernor} from "src/MyGovernor.sol";
import {GovToken} from "src/GovToken.sol";
import {Box} from "src/Box.sol";
import {TimeLock} from "src/TimeLock.sol";

contract MyGovernorTest is Test {

    MyGovernor governor;
    GovToken govToken;
    Box box;
    TimeLock timeLock;

    // Leaving empty => everyone can propose + execute
    address[] proposers;
    address[] executors;

    uint256 MIN_DELAY_IN_SECONDS = 69;

    address immutable USER = makeAddr("user");
    uint256 constant START_AMOUNT = 420 ether;

    // XXX: This constants are based of the code of MyGovernor
    uint256 public constant VOTING_PERIOD = 50400; // This is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, START_AMOUNT);

        vm.startPrank(USER);
        govToken.delegate(USER);
        timeLock = new TimeLock(MIN_DELAY_IN_SECONDS, proposers, executors);
        governor = new MyGovernor(govToken, timeLock);

        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 proposalRole = timeLock.PROPOSER_ROLE();

        timeLock.grantRole(proposalRole, address(governor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, USER);
        vm.stopPrank();

        box = new Box();
        box.transferOwnership(address(timeLock));
    }

    function testCantUpdateBoxWithoutGovernor() public {
        vm.expectRevert();
        box.storeNumber(420);
    }

    function testGovernorUpdate() public {
        assert(box.getNumber() == 0); // Initial value

        // Some preparations
        uint256 valueToStore = 11;
        bytes memory data = abi.encodeWithSignature("storeNumber(uint256)", valueToStore); 
        string memory description = "Store value 11 in Box";

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        values[0] = 0;
        targets[0] = address(box);
        calldatas[0] = data;
        
        // Fist we need to propose changing the Box Contract
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        console.log("Proposal State:", uint256(governor.state(proposalId)));
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // Then Vote 
        // XXX: From the docs: 0 - Against, 1 - For, 2 - Abstain
        string memory reason = "Shoto sam Emo Tsanev";
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, 1, reason);

        // Skip time to move the voting period -> Win the vote
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // Queue the transaction (IDK why they dont use proposal ids)
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets , values, calldatas, descriptionHash);
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        vm.roll(block.number + MIN_DELAY_IN_SECONDS + 1);
        vm.warp(block.timestamp + MIN_DELAY_IN_SECONDS + 1);

        // Execute the transaction
        governor.execute(targets, values, calldatas, descriptionHash);
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // Assert
        assert(box.getNumber() == valueToStore);
    }
}
