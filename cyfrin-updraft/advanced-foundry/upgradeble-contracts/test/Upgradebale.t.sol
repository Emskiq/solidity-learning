//newBox SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";

import {BoxV1} from "src/BoxV1.sol";
import {BoxV2} from "src/BoxV2.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

import {DeployBox} from "script/DeployBox.s.sol";
import {UpgradeBox} from "script/UpgradeBox.s.sol";

contract UpgradebleTests is Test {
        DeployBox deployer;
        UpgradeBox upgrader;

        BoxV1 public box1;
        BoxV2 public box2;

        address proxy;

        address public OWNER = makeAddr("Owner");

        function setUp() public {
               deployer = new DeployBox();
               upgrader = new UpgradeBox();

        //        vm.prank(OWNER);
               proxy = deployer.deployBox();
        }

        function testStartWithBoxV1() public {
               assertEq(BoxV1(proxy).version(), 1); 

               BoxV1(proxy).setNumber(420);
               assertEq(BoxV1(proxy).getNumber(), 420);

               vm.expectRevert();
               BoxV2(proxy).setNumber(12931041);

        }

        function testUpgrade() public {

                BoxV2 box2 = new BoxV2(); 

                // Ebasi HACK-a....
                vm.prank(BoxV1(proxy).owner());
                BoxV1(proxy).transferOwnership(msg.sender);

                upgrader.upgradeProxy(proxy, address(box2));


                uint256 expectedVersion = 2;
                assertEq(BoxV2(proxy).version() , expectedVersion);

                BoxV2(proxy).setNumber(69);
                assertEq(BoxV2(proxy).getNumber(), 69);
        }
}
