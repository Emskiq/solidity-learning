// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Contract used to remove/pop element
// from an array by shifting
contract ArrayRemove {
    uint[] public arr;

    function push(uint _x) external {
        arr.push(_x);
    }

    function pop() external {
        arr.pop();
    }

    function remove(uint idx) external {
        require(idx < arr.length, "Index exceeds the array lenght");

        for (uint i = idx; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }

    function arrLength() public view returns(uint) {
        return arr.length;
    }
}
