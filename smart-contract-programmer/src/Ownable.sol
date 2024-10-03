// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error NotOwner(address caller);

contract Ownable {
    address public owner;
    int public x;

    constructor() {
        owner = msg.sender;
        x = 69;
    }

    modifier onlyOwner(address caller) {
        if (owner != caller) {
            revert NotOwner(caller);
        }
        _;
    }

    function setNewOwner(address newOwner) external onlyOwner(msg.sender) {
        owner = newOwner;
    }

    function setX(int _x) external {
        require(_x == 420 || _x == 69, "X value must be nice!");
        x = _x;
    }
}
