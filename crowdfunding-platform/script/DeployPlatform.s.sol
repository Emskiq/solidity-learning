// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {HelperConfig} from "./HelperConfig.s.sol";

import {CrowdfundingPlatform} from "src/CrowdfundingPlatform.sol";
import {PlatformToken} from "src/PlatformToken.sol";

contract DeployPlatform is Script {
    PlatformToken token;
    CrowdfundingPlatform platform;

    // For 1 ETH invested to earn 1000 tokens, the ratio is represented with 18 decimals.
    uint256 constant ETH_RATIO = 1000 * 1e18;
    uint256 constant FINALIZE_AWARD = 1e18; // 100 tokens?

    function run() public returns(CrowdfundingPlatform, PlatformToken) {
        token = new PlatformToken();
        platform = new CrowdfundingPlatform(token, ETH_RATIO, FINALIZE_AWARD);

        vm.prank(address(this));
        platform.transferOwnership(msg.sender);
        token.transferOwnership(address(platform));

        return (platform, token);
    }
}
