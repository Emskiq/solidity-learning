// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PlatformToken} from "src/PlatformToken.sol";

contract PlatformTokenTests is Test {
    PlatformToken token;
    address USER1 = makeAddr("USER1");

    function setUp() public {
        token = new PlatformToken();
    }

    function testTokenNameAndSymbol() public view {
        // Basic checks for name and symbol
        assertEq(token.name(), "PlatfromToken");
        assertEq(token.symbol(), "PTKN");
    }

    function testMintZeroReverts() public {
        // Should revert if _amount <= 0
        vm.expectRevert(PlatformToken.PlatformToken__MustBeMoreThanZero.selector);
        token.mint(address(this), 0);
    }

    function testMintToZeroAddressReverts() public {
        // Should revert if _to == address(0)
        vm.expectRevert(PlatformToken.PlatformToken__CannotMintToZeroAddress.selector);
        token.mint(address(0), 1000);
    }

    function testMintByNonOwnerReverts() public {
        // Non-owner tries to mint
        vm.prank(USER1);
        vm.expectRevert();
        token.mint(USER1, 1000);
    }

    function testMintAsOwnerIncreasesBalance() public {
        // Happy path: owner mints tokens to USER1
        uint256 initialBal = token.balanceOf(USER1);
        token.mint(USER1, 1000);
        uint256 newBal = token.balanceOf(USER1);
        assertEq(newBal, initialBal + 1000, "Balance should increase by minted amount");
    }
}
