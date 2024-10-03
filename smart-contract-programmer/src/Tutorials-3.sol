// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// Contract used to play around while studying
/// from Smart Contract Programmer's tutorials
/// Videos - Ownable till Mapping
contract Tutorials3 {
    // Function outputs
    function returnsMany() public pure returns(uint, bool) {
        return (1, true);
    }

    function named() public pure returns(uint x, bool b) {
        return (1, true);
    }

    // ill-assigned - saves gas, because one less copy
    function assinged() public pure returns(uint x, bool b) {
        x = 1;
        b = true;
    }

    // destructing assignemnent
    function destructingAssignement() public pure {
        (uint x, bool b) = returnsMany();
        (, bool _b) = returnsMany();
    }

    // Arrays
    uint[] public nums;
    uint[69] public numsFixed = [1, 2]; // cannot exceed the maximum elements but can be lower

    function push_to_nums(uint x) external {
        nums.push(x);
    }

    function examples() external {
        uint len = nums.length;
        delete nums[4]; // what will happen if there is not enough lenght?
                        // - panic: array out-of-bounds access (0x32)
        nums.pop();

        uint[] memory a = new uint[](6);
    }

    // !!! Not recommended: Can use all the gas becasue we do NOT know the
    //     size of the array - a hacker can make it big...
    function returnsArray() external view returns(uint[] memory) {
        return nums;
    }


    // Mapping
    mapping(address => uint) public balances;
    mapping(address => mapping(address => bool)) public isFriend;

    function setYouBalance(uint _balance) external {
        balances[msg.sender] = _balance;
    }

    function deleteYouBalance(uint _balance) external {
        delete balances[msg.sender];
    }

    function getYouBalance() public view returns(uint) {
        return balances[msg.sender];
    }
}
