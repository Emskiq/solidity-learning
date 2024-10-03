// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// Contract used to play around while studying
/// from Smart Contract Programmer's tutorials
/// Videos - Counter till Ownable
contract Tutorials2 {
    // Defaul Values
    bool public b; // false
    uint public ui; // 0
    int public i; // 0
    address public a; // 0x0000...
    bytes32 public b32; // 0x000.... (64 0s)

    // Constants - main benefit is gas optimisation
    address public constant EMSKIQ_ADDRESS = 0xD81993511065fB80Fa160DebF57E2FceD1Cf4DbA;

    // if-else
    function foo_if_else_less_than_5(uint _x) external pure returns (bool) {
        if (_x < 5) {
            return true;
        } else {
            return false;
        }
    }

    // ternary operation
    function foo_ternay_less_than_5(uint _x) external pure returns (bool) {
        return _x < 5 ? true : false;
    }

    // Loops
    function loop(uint _n) external pure {
        for (uint counter_1 = 0; counter_1 < 10; counter_1++) {
            // code
            if (counter_1 == 3) {
                continue;
            }
        }

        // BIG L - Consider max iterations of the loop always!
        uint counter_2 = 0;
        while (counter_2 < _n) {
            // code
            counter_2++;
        }
    }

    // Custom errors, requires, assert, revert
    function testRequire(uint _i) public pure {
        require(_i <= 10, "i > 10");
        // code
    }

    function testRevert(uint _i) public pure {
        if (_i > 10) {
            revert("i > 10");
        }
        // code
    }

    function testAssert() public view {
        assert(b == false);
    }

    error MyError(address caller, uint i);

    // custom errors are saving gas - because of the string in the require (...) statement
    function testRevertCustomError(uint _i) public view {
        if (_i > 10) {
            revert MyError(msg.sender, _i);
        }
        // code
    }


    // Function modifiers
    bool public paused;
    uint public count;

    function setPause(bool _paused) public {
        paused = _paused;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _; // the rest of the code of the function
    }

    modifier sandwich(uint _inc, uint _dec) {
        count += _inc;
        _;
        count -= _dec;
    }

    function inc() external whenNotPaused {
        count++;
    }

    function dec() external whenNotPaused {
        count--;
    }

    function foooo(uint _x) external whenNotPaused sandwich(10, _x) {
        count += _x;
    }
}
