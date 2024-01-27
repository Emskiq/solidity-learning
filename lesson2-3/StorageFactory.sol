// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageFactory {

    SimpleStorage[] public simpleStorages;

    function createSimpleStorageContract() public {
        simpleStorages.push (new SimpleStorage());
    }

    function sfStore (uint256 _simpleStorageIdx, uint256 _newSimpleStorageNum) public  {
        /// address
        /// abi
        simpleStorages[_simpleStorageIdx].store(_newSimpleStorageNum);
    }

    function sfGet (uint256 _ssIdx) public view returns(uint256) {
        return simpleStorages[_ssIdx].retrieve();
    }
}
