// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {StableCoin} from "src/StableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSCEngine is Script {

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    StableCoin public token;
    DSCEngine public engine;

    function run() public returns(StableCoin, DSCEngine, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        address wethUsdPriceFeed = networkConfig.wethPriceFeed;
        address wbtcUsdPriceFeed = networkConfig.wbtcPriceFeed;
        address weth = networkConfig.weth;
        address wbtc = networkConfig.wbtc;
        uint256 deployerKey = networkConfig.deployKey;

        // Fill the arrays
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        
        vm.startBroadcast();

        engine = new DSCEngine(tokenAddresses, priceFeedAddresses);
        token = StableCoin(engine.getStableCoinAddress());

        vm.stopBroadcast();

        return (token,engine, helperConfig);
    }
}
