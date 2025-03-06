// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/*
 * @title TimeLock
 * @author Emil Tsanev
 *
 * This is the contract meant to lock for a certain time our Governor
 * contract before voted proposal is executed.
 */
contract TimeLock is TimelockController {
    // constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin) {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors)
        TimelockController(minDelay, proposers, executors, msg.sender)
    {}

}
