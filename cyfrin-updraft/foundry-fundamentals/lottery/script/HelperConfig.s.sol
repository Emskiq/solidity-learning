// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {LinkToken} from "test/LinkTokenMock.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract Constants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 1e15;

    uint256 public constant MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, Constants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        uint256 subscriptionId;
        address vrfCordinatorAddress;
        bytes32 gasLane;
        address link;
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
            return getAnvilLocalConfig();
        }
        else if (block.chainid == MAINNET_CHAIN_ID) {
            return getMainnetConfig();
        }
        else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig ({
            entranceFee: 0.01 ether,
            interval: 30,
            subscriptionId: 8492206078300065517564709339536974336332291323049086707992142320768219379749, // My personal one
            vrfCordinatorAddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x7b9a36F1154675dBB22D679FA4A223cF25d04b90
        });
        return sepoliaConfig;
    }

    function getAnvilLocalConfig() public returns(NetworkConfig memory) {
        if (currentLocalConfig.vrfCordinatorAddress != address(0)) {
            return currentLocalConfig;
        }

        console.log("Mocking the vrf");
        vm.startBroadcast();

        VRFCoordinatorV2_5Mock mockVRFCordinator = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        LinkToken link = new LinkToken();
        uint256 subscriptionId = mockVRFCordinator.createSubscription();

        vm.stopBroadcast();

        console.log("Mocking the vrf received sub id: ", subscriptionId);

        NetworkConfig memory anvilConfig = NetworkConfig ({
            entranceFee: 0.0069 ether,
            interval: 30,
            subscriptionId: subscriptionId,
            vrfCordinatorAddress: address(mockVRFCordinator),
            gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9, /// DOES NOT MATTER (BECAUSE WE ARE USING MOCK)
            link: address(link),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 // default foundry sender (from Base.sol)
        });

        currentLocalConfig = anvilConfig;
        return anvilConfig;
    }

    function getMainnetConfig() public pure returns(NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig ({
            entranceFee: 0.01 ether,
            interval: 30,
            subscriptionId: 0,
            vrfCordinatorAddress: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            gasLane: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9, // 200 gwei keyhash
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            account: 0x0000000000000000000000000000000000000000 // TODO??
        });
        return mainnetConfig;
    }
}
