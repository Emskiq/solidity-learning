// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public s_number;
    bool public s_boolean;

    string private s_name;

    // not shown as storage variable
    uint16 immutable private i_number;

    mapping(address => uint256) private s_maps;

    // not shown as storage variable
    uint24 constant private SOME_CONST = 69;

    function setNumber(uint256 newNumber) public {
        s_number = newNumber;
    }

    function increment() public {
        s_number++;
    }
}
