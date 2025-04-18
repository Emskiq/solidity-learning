// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract ManualToken {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    mapping(address => uint256) private s_balances;

    // function name() public view returns (string) {
    //     return "Manual Token";
    // }
    //
    // function decimals() public view returns (uint8) {
    //     return 18;
    // }
    //
    // function totalSupply() public view returns (uint256) {
    //     return 100 ether;
    // }
    //
    // function balanceOf(address _owner) public view returns (uint256 balance) {
    //     return s_balances[_owner];
    // }
    //
    // function transfer(address _to, uint256 _value) public returns (bool success) {
    //     uint256 prevBalane = balanceOf(msg.sender) + balanceOf(_to);
    //     s_balances[msg.sender] -= _value;
    //     s_balances[_to] += _value;
    //     require(balanceOf(msg.sender) + balanceOf(_to) == prevBalane);
    // }
    //
    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    // }
    //
    // function approve(address _spender, uint256 _value) public returns (bool success) {
    // }
    //
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // }

}
