// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private s_num;

    event NumberChanged(uint256 number);

    constructor() Ownable(msg.sender) { }

    function storeNumber(uint256 newNum) public onlyOwner {
        s_num = newNum;
        emit NumberChanged(newNum);
    }


    function getNumber() external view returns(uint256) {
        return s_num;
    }

}
