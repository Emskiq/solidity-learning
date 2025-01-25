// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/MockAggregator.sol";

// Mock
contract HelperConfig is Script {
    NetworkConfig public currentConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 69e8;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            currentConfig = getSepoliaEthConfig();
        }
        else if (block.chainid == 1) {
            currentConfig = getMainnetConfig();
        }
        else {
            currentConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig ({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getAnvilEthConfig() public returns(NetworkConfig memory) {
        if (currentConfig.priceFeed != address(0)) {
            return currentConfig;
        }

        vm.startBroadcast();

        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig ({ priceFeed: address(mockPriceFeed) });
        return anvilConfig;
    }

    function getMainnetConfig() public pure returns(NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig ({
            priceFeed: 0x1111111111111111111111111111111111111111 // kur
        });
        return mainnetConfig;
    }
}
