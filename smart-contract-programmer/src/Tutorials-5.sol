// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// Contract used to play around while studying
/// from Smart Contract Programmer's tutorials
/// Videos - Inheritance - 


// Inheritance
contract A {
    function foo() public pure virtual returns(string memory) {
        return "foo(A)";
    }

    function bar() public pure virtual returns(string memory) {
        return "bar(A)";
    }

    function baz() public pure returns(string memory) {
        return "baz(A)";
    }
}

contract B is A {
    function foo() public pure override returns(string memory) {
        return "foo(B)";
    }

    function bar() public pure override returns(string memory) {
        return "bar(B)";
    }
}
