// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";

import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";

abstract contract Constants {
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;

    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    address constant BURNER_WALLET = 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D;

    // address constant FOUNDRY_DEFAULT_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
}



contract HelperConfig is Script, Constants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
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
        else if (block.chainid == ZKSYNC_SEPOLIA_CHAIN_ID) {
            return getZKSyncSepoliaConfig();
        }
        else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public view returns(NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig ({
            entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789,
            account: BURNER_WALLET
        });
        return sepoliaConfig;
    }

    function getZKSyncSepoliaConfig() public view returns(NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig ({
            entryPoint: address(0),
            account: BURNER_WALLET
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilLocalConfig() public returns(NetworkConfig memory) {
        if (currentLocalConfig.account != address(0)) {
            return currentLocalConfig;
        }

        console.log("Deploying mocks");
        vm.startBroadcast(ANVIL_DEFAULT_ACCOUNT);

        EntryPoint entryPoint = new EntryPoint();

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig ({
            entryPoint: address(entryPoint),
            account: ANVIL_DEFAULT_ACCOUNT
        });

        currentLocalConfig = anvilConfig;
        return currentLocalConfig;
    }
}

