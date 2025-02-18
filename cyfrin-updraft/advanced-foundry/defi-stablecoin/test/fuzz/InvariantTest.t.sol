// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Vm} from "forge-std/Vm.sol";

import {DSCEngine} from "src/DSCEngine.sol";
import {StableCoin} from "src/StableCoin.sol";

import {DeployDSCEngine} from "script/DeployDSCEngine.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {Handler} from "./Handler.t.sol";


// 2 important questions: What are our invarants???

// 1) total supply of StableCoin be less TotalValueCollateral in USD
// 2) pure view function should be always non-revertable (evergreen invariant)

contract DSCEngineInvariantTest is StdInvariant, Test {

    StableCoin public stableCoin;
    DSCEngine public dscEngine;
    HelperConfig public config;
    Handler public handler;

    address weth;
    address wbtc;

    address EMSKI = makeAddr("EMSKI");
    address LIQUIDATOR = makeAddr("LIQUIDATOR");

    uint256 constant COLLATERAL_AMOUNT = 5e18;
    uint256 constant STARTING_WETH_BALANCE = 10e18;

    ERC20Mock public wethToken;
    ERC20Mock public wbtcToken;

    function setUp() public {
        DeployDSCEngine deployer = new DeployDSCEngine();
        (stableCoin, dscEngine, config) = deployer.run();

        HelperConfig.NetworkConfig memory networkConfig = config.getConfig();

        weth = networkConfig.weth;
        wbtc = networkConfig.wbtc;
        wethToken = ERC20Mock(weth);
        wbtcToken = ERC20Mock(wbtc);

        handler = new Handler(dscEngine, stableCoin);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanSupply() public view {
        uint256 totalSupply = stableCoin.totalSupply();
        uint256 wethDeposited = wethToken.balanceOf(address(dscEngine));
        uint256 wbtcDeposited = wbtcToken.balanceOf(address(dscEngine));

        uint256 wethValue = dscEngine.getUsdValueOfToken(weth, wethDeposited);
        uint256 wbtcValue = dscEngine.getUsdValueOfToken(wbtc, wbtcDeposited);

        console.log("weth value: ", wethValue);
        console.log("wbtc value: ", wbtcValue);
        console.log("times mint called: ", handler.timesMintCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }
}

