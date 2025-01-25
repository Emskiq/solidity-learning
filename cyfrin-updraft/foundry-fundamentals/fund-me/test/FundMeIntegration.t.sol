// SPDX-Licence-Identiefier: MITticketTransfer

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

import {DeployFundMe} from "../script/FundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../script/Interaction.s.sol";

contract FundMeIntegration is Test {
    FundMe fundMe;

    address USER = makeAddr("USER");

    function setUp() external {
        // call deploy
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, 69 ether);
    }

    function testCanFundInteraction() external {
        FundFundMe fundFundMe = new FundFundMe();
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();

        fundFundMe.fundFundMe(address(fundMe));
        withdrawFundMe.withdrawFundMe(address(fundMe));
    }
}
