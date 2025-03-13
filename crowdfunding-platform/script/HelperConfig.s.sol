// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

abstract contract Constants {
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
}

contract HelperConfig is Script, Constants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 deployKey;
    }

    NetworkConfig public currentLocalConfig;

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        console.log("getting chain id: ", chainId);
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            return getSepoliaEthConfig();
        }
        else if (block.chainid == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilLocalConfig();
        }
        else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public view returns(NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig ({
            deployKey : vm.envUint("PRIVATE_KEY")
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilLocalConfig() public returns(NetworkConfig memory) {
        if (currentLocalConfig.deployKey != 0) {
            return currentLocalConfig;
        }

        NetworkConfig memory anvilConfig = NetworkConfig ({
            deployKey : DEFAULT_ANVIL_PRIVATE_KEY
        });

        currentLocalConfig = anvilConfig;
        return anvilConfig;
    }
}