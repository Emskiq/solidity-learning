// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Contract which holds a mapping
// which we can iterate and get the size of
contract IterableMap {
    mapping(address => uint) public balances;
    address[] public arr;

    function add_balance_for(address _address, uint _balance) external {
        require(_balance > 0, "You can't insert zero balance for an address");

        if (balances[_address] == 0) {
            arr.push(_address);
        }
        balances[_address] = _balance;
    }

    function length() public view returns(uint) {
        return arr.length;
    }
}
