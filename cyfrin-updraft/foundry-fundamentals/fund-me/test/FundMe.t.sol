// SPDX-Licence-Identiefier: MITticketTransfer

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/FundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("USER");

    function setUp() external {
        // call deploy
        DeployFundMe deployScript = new DeployFundMe();
        fundMe = deployScript.run();
        vm.deal(USER, 69e18);
    }

    function testMinDollar() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerSendre() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testVersionFundMe() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testExpectFundFail() public {
        vm.expectRevert(bytes("You need to spend more ETH!"));
        fundMe.fund();
    }

    function testExpectFundSucess() public {
        vm.prank(USER);

        uint256 amountToFund = 10e18;
        fundMe.fund{value: amountToFund}();
        uint256 amountFunded = fundMe.getAmountTOFundingAddres(USER);

        assertEq(amountFunded, amountToFund);
    }

    function testFunders() public {
        vm.prank(USER);

        uint256 amountToFund = 10e18;
        fundMe.fund{value: amountToFund}();
        address userFunder = fundMe.getFunder(0);

        assertEq(USER, userFunder);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 10e18}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdraw() public funded {
        uint256 startBalanceOwner = fundMe.getOwner().balance;
        uint256 startBalanceContract = address(fundMe).balance;

        uint256 startGas = gasleft();

        vm.txGasPrice(1);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endGas = gasleft();
        uint256 gasUsed = (startGas - endGas) * tx.gasprice;
        console.log("Gas used: ", gasUsed);

        uint256 endBalanceOwner = fundMe.getOwner().balance;
        uint256 endBalanceContract = address(fundMe).balance;

        assertEq(endBalanceContract, 0);
        assertEq(endBalanceOwner, startBalanceOwner + startBalanceContract);
    }
}

