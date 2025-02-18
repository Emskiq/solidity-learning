// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";

import {MockV3Aggregator} from "test/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

abstract contract Constants {
    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2500e8;
    int256 public constant BTC_USD_PRICE = 8800e8;

    uint256 public constant INITIAL_WETH_AMOUNT = 420e12;
    uint256 public constant INITIAL_WBTC_AMOUNT = 420e12;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
}

contract HelperConfig is Script, Constants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address wethPriceFeed;
        address wbtcPriceFeed;
        address weth;
        address wbtc;
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
            wethPriceFeed : 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcPriceFeed : 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployKey : vm.envUint("PRIVATE_KEY")
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilLocalConfig() public returns(NetworkConfig memory) {
        if (currentLocalConfig.wethPriceFeed != address(0)) {
            return currentLocalConfig;
        }

        console.log("Mocking the PriceFeeds, WETH and WBTC...");

        vm.startBroadcast();

        MockV3Aggregator ethMockPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        ERC20Mock wethMock = new ERC20Mock();
        wethMock.mint(msg.sender, INITIAL_WETH_AMOUNT);

        MockV3Aggregator btcMockPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        ERC20Mock wbtcMock = new ERC20Mock();
        wbtcMock.mint(msg.sender, INITIAL_WBTC_AMOUNT);

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig ({
            wethPriceFeed : address(ethMockPriceFeed),
            wbtcPriceFeed : address(btcMockPriceFeed),
            weth: address(wethMock),
            wbtc: address(wbtcMock),
            deployKey : DEFAULT_ANVIL_PRIVATE_KEY
        });

        currentLocalConfig = anvilConfig;
        return anvilConfig;
    }
}
