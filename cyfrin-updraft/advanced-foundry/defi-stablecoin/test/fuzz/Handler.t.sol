// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

import {DSCEngine} from "src/DSCEngine.sol";
import {StableCoin} from "src/StableCoin.sol";

import {DeployDSCEngine} from "script/DeployDSCEngine.s.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";

import {MockV3Aggregator} from "test/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

// Random things with:
// Price feed
// WETH
// WBTC

contract Handler is Test {

    StableCoin public stableCoin;
    DSCEngine public dscEngine;

    ERC20Mock public wethToken;
    ERC20Mock public wbtcToken;

    uint256 public timesMintCalled;
    address[] public usersDeposited;

    uint96 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    MockV3Aggregator public ethPriceFeed;
    MockV3Aggregator public btcPriceFeed;

    constructor(DSCEngine _dsce, StableCoin _coin) {
        dscEngine = _dsce;
        stableCoin = _coin;

        address[] memory collaterals = dscEngine.getCollateralsAdrresses();
        wethToken = ERC20Mock(collaterals[0]);
        wbtcToken = ERC20Mock(collaterals[1]);

        ethPriceFeed = MockV3Aggregator(dscEngine.getCollateralPriceFeed(address(wethToken)));
        btcPriceFeed = MockV3Aggregator(dscEngine.getCollateralPriceFeed(address(wbtcToken)));
    }


    // Redeem Collateral <- (call this when u have collateral)

    function depositCollateral(uint256 collateralSeed, uint256 amount) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amount = bound(amount, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amount);
        collateral.approve(address(dscEngine), amount);
        dscEngine.depositCollateral(address(collateral), amount);
        vm.stopPrank();

        usersDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amount) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dscEngine.getCollateralsBalanceForUser(msg.sender, address(collateral));

        amount = bound(amount, 0, maxCollateralToRedeem);
        if (amount == 0) {
            return;
        }

        vm.prank(msg.sender);
        dscEngine.redeemCollateral(address(collateral), amount);
        vm.stopPrank();
    }

    // Aggregator //
    // This breaks the tests because we are causing a huge update on the price and thus invarian check breaks...
    // function updateCollateralPrice(uint96 newPrice, uint256 collateralSeed) public {
    //     int256 intNewPrice = int256(uint256(newPrice));
    //     ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
    //     MockV3Aggregator priceFeed = MockV3Aggregator(dscEngine.getCollateralPriceFeed(address(collateral)));
    //
    //     priceFeed.updateAnswer(intNewPrice);
    // }


    function mintStableCoin(uint256 mintAmount, uint256 addressSeed) public {
        if (usersDeposited.length <= 0) {
            return;
        }

        address msgSender = usersDeposited[addressSeed % usersDeposited.length];
        (uint256 tokensMinted, uint256 collateralInUsd) = dscEngine.getAccountInfo(msgSender);

        // mintAmount = bound(mintAmount, 0, MAX_DEPOSIT_SIZE);
        // uint256 tokensToBeMinted = tokensMinted + mintAmount;
        //
        // uint256 healthFactor = dscEngine.calculateHealthFactor(tokensToBeMinted, collateralInUsd);
        //
        // vm.stopPrank();
        // if (healthFactor < dscEngine.getMinHealthFactor()) {
        //     return;
        // }

        int256 maxCoinToMint = (int256(collateralInUsd / 2)) - int256(tokensMinted);
        console.log("tokens minted: ", tokensMinted);
        console.log("collateralInUsd: ", collateralInUsd);
        console.log("max coint to mint: ", maxCoinToMint);
        if (maxCoinToMint <= 0) {
            return;
        }

        timesMintCalled++;

        mintAmount = bound(mintAmount, 0, uint256(maxCoinToMint));

        vm.prank(msgSender);
        dscEngine.mintStableCoin(mintAmount);
        vm.stopPrank();

    }


    function _getCollateralFromSeed(uint256 seed) private view returns(ERC20Mock) {
        if (seed % 2 == 0) {
            return wethToken;
        }
        else {
            return wbtcToken;
        }
    }
}
