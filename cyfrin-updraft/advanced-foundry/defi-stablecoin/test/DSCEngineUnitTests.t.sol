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

contract DSCEngineTest is Test {
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    StableCoin public stableCoin;
    DSCEngine public dscEngine;
    HelperConfig public config;

    address weth;
    address wethPricefeed;
    uint256 deployKey;

    address EMSKI = makeAddr("EMSKI");
    address LIQUIDATOR = makeAddr("LIQUIDATOR");

    uint256 constant COLLATERAL_AMOUNT = 5e18;
    uint256 constant STARTING_WETH_BALANCE = 10e18;

    ERC20Mock public wethToken;

    function setUp() public {
        DeployDSCEngine deployer = new DeployDSCEngine();
        (stableCoin, dscEngine, config) = deployer.run();

        HelperConfig.NetworkConfig memory networkConfig = config.getConfig();

        weth = networkConfig.weth;
        wethPricefeed = networkConfig.wethPriceFeed;
        deployKey = networkConfig.deployKey;

        wethToken = ERC20Mock(weth);
        wethToken.mint(EMSKI, STARTING_WETH_BALANCE);
        wethToken.mint(LIQUIDATOR, 10 * STARTING_WETH_BALANCE); // a little Overkill pbly
    }

    // ------ Constructor tests ------
    function testRevertInConstructorIfArrayLensDontMatch() public {
        address[] memory tokenAddresses = new address[](2);
        address[] memory priceFeedAddresses = new address[](1);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressAndPriceFeedsAddressNotEqualLen.selector);
        DSCEngine wrongEngine = new DSCEngine(tokenAddresses, priceFeedAddresses);
    }
    // --------------------------------------


    // ------ Price tests ------
    function testGetUsdValue() public view {
        uint256 ethAmount = 2e18;
        // 2 eth (2e18) * 2500 USD = 6000 USD (6000e18)
        uint256 expectedAmount = 5000e18;
        uint256 amountInUsd = dscEngine.getUsdValueOfToken(weth, ethAmount);
        assertEq(expectedAmount, amountInUsd);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        // 100 / 2500 = 0.3333
        uint256 expectedAmount = 0.04 ether;
        uint256 amountInToken = dscEngine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedAmount, amountInToken);
    }
    // --------------------------------------


    // ------ GetAccountInfo and Health factor tests ------
    function testGetAccountInfo() public {
        uint256 mintAmount = 1000e18;
        vm.prank(EMSKI);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.prank(EMSKI);
        dscEngine.depositCollateralAndMintStableCoin(weth, COLLATERAL_AMOUNT, mintAmount);

        (uint256 tokensMinted, uint256 collateralUsd) = dscEngine.getAccountInfo(EMSKI);
        uint256 expectedCollateralUsd = dscEngine.getUsdValueOfToken(weth, COLLATERAL_AMOUNT);
        assertEq(tokensMinted, mintAmount, "Token minted mismatch");
        assertEq(collateralUsd, expectedCollateralUsd, "Collateral USD mismatch");
    }

    function testGetHealthFactor() public {
        uint256 emskiqHealthFactorBeforeDeposit = dscEngine.getHealthFactor(EMSKI);

        uint256 mintAmount = 1000e18;
        vm.prank(EMSKI);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.prank(EMSKI);
        dscEngine.depositCollateralAndMintStableCoin(weth, COLLATERAL_AMOUNT, mintAmount);

        uint256 emskiqHealthFactorAfterDeposit = dscEngine.getHealthFactor(EMSKI);

        assertEq(emskiqHealthFactorBeforeDeposit, type(uint256).max, "Health factor of EMSKIQ Not zero before depositing any funds.");
        assertNotEq(emskiqHealthFactorBeforeDeposit, emskiqHealthFactorAfterDeposit, "Health factor fo emskiq didn't change after depositing");
    }
    // --------------------------------------



    // ------ Deposit collateral tests ------
    modifier depositedCollateral() {
        // EMSKI approves DSCEngine.
        vm.prank(EMSKI);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);

        // Deposit collateral.
        vm.prank(EMSKI);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
        _;
    }

    modifier depositedCollateralAndMintedSC() {
        uint256 collateralUsd = dscEngine.getUsdValueOfToken(weth, COLLATERAL_AMOUNT);
        uint256 maxMintable = collateralUsd / 2; // Maximum allowed minted amount.
        uint256 amountToMint = maxMintable / 2;  // Mint half of that maximum.

        vm.prank(EMSKI);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);

        vm.prank(EMSKI);
        dscEngine.depositCollateralAndMintStableCoin(weth, COLLATERAL_AMOUNT, amountToMint);
        _;
    }

    function testDepositCollateralRevertIfZero() public {
        ERC20Mock(weth).approve(EMSKI, COLLATERAL_AMOUNT);

        vm.prank(EMSKI);
        vm.expectRevert(DSCEngine.DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngine.depositCollateral(weth, 0);
    }

    function testDepositCollateralRevertsForNotAllowedToken() public {
        // Use a fake token address that is not in the allowed list.
        address fakeToken = makeAddr("FAKE");
        vm.prank(EMSKI);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedTokenCollateral.selector);
        dscEngine.depositCollateral(fakeToken, COLLATERAL_AMOUNT);
    }

    function testDepositCollateralSuccess() public {
        // EMSKI approves DSCEngine.
        vm.prank(EMSKI);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);

        // Expect the CollateralDeposited event.
        vm.expectEmit(true, true, true, true);
        emit CollateralDeposited(EMSKI, weth, COLLATERAL_AMOUNT);

        // Deposit collateral.
        vm.prank(EMSKI);
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);

        // Verify the deposited USD value is as expected.
        uint256 expectedUsd = dscEngine.getUsdValueOfToken(weth, COLLATERAL_AMOUNT);
        uint256 actualUsd = dscEngine.getCollateralDepositedInUsdForUser(EMSKI);
        assertEq(expectedUsd, actualUsd, "Collateral USD value mismatch");
    }

    function testDepositCollateralFailsIfInsufficientAllowance() public {
        // Do NOT approve DSCEngine to spend EMSKI's tokens.
        vm.prank(EMSKI);
        vm.expectRevert();
        dscEngine.depositCollateral(weth, COLLATERAL_AMOUNT);
    }
    // --------------------------------------

    // ------ Mint Stable coins tests ------
    function testMintStableCoinRevertsWithoutCollateral() public {
        vm.prank(EMSKI);
        vm.expectRevert(DSCEngine.DSCEngine__NotEnoughCollateralDeposited.selector);
        dscEngine.mintStableCoin(1000e18);
    }

    function testMintZeroStableCoinReverts() public {
        vm.prank(EMSKI);
        vm.expectRevert(DSCEngine.DSCEngine__AmountShouldBeMoreThanZero.selector);
        dscEngine.mintStableCoin(0);
    }

    /// @notice Test that after depositing sufficient collateral, minting stable coin succeeds.
    /// The amount minted should match the user’s stable coin balance.
    function testMintStableCoinSuccess() public
        depositedCollateral
    {
        // According to the engine's logic, health factor is acceptable if:
        // collateralDepositedInUsd >= 2 * stableCoinMinted.
        // For simplicity, we mint an amount safely below the max allowed.
        uint256 collateralUsd = dscEngine.getCollateralDepositedInUsdForUser(EMSKI);
        uint256 maxMintable = collateralUsd / 2; // Maximum allowed minted amount.
        uint256 amountToMint = maxMintable / 2;  // Mint half of that maximum.

        vm.prank(EMSKI);
        dscEngine.mintStableCoin(amountToMint);

        uint256 stableCoinBalance = stableCoin.balanceOf(EMSKI);

        (uint256 tokensMinted, uint256 amountInUsdDeposited) = dscEngine.getAccountInfo(EMSKI);

        assertEq(stableCoinBalance, amountToMint, "Stable coin minting did not succeed");
        assertEq(collateralUsd, amountInUsdDeposited, "Collateral deposit did not succeed");
    }

    function testMintStableCoinOverTheHealthLimit() public
        depositedCollateral
    {
        // According to the engine's logic, health factor is acceptable if:
        // collateralDepositedInUsd >= 2 * stableCoinMinted.
        // For simplicity, we mint an amount safely below the max allowed.
        uint256 collateralUsd = dscEngine.getCollateralDepositedInUsdForUser(EMSKI);
        uint256 maxMintable = collateralUsd; // Maximum allowed minted amount
        uint256 amountToMint = maxMintable;  // Mint half of that maximum.

        vm.prank(EMSKI);
        vm.expectRevert(DSCEngine.DSCEngine__NotEnoughCollateralDeposited.selector);
        dscEngine.mintStableCoin(amountToMint);
    }
    // --------------------------------------


    // ------ Deposit and Mint Stable coins ------
    function testDepositAndMintStableCoinSuccess() public
    {
        uint256 collateralUsd = dscEngine.getUsdValueOfToken(weth, COLLATERAL_AMOUNT);
        uint256 maxMintable = collateralUsd / 2; // Maximum allowed minted amount.
        uint256 amountToMint = maxMintable / 2;  // Mint half of that maximum.

        vm.prank(EMSKI);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);

        // Deposit collateral and Mint
        vm.prank(EMSKI);
        dscEngine.depositCollateralAndMintStableCoin(weth, COLLATERAL_AMOUNT, amountToMint);

        uint256 stableCoinBalance = stableCoin.balanceOf(EMSKI);

        (uint256 tokensMinted, uint256 amountInUsdDeposited) = dscEngine.getAccountInfo(EMSKI);

        assertEq(stableCoinBalance, amountToMint, "Stable coin minting did not succeed");
        assertEq(collateralUsd, amountInUsdDeposited, "Collateral deposit did not succeed");
    }
    // --------------------------------------

    // ------ Redeem collateral tests ------
    function testRedeemCollateralSuccess() public
        depositedCollateral
    {
        uint256 collateralUsd = dscEngine.getCollateralDepositedInUsdForUser(EMSKI);
        uint256 maxMintable = collateralUsd / 2;
        uint256 amountToMint = maxMintable / 4;  // Mint small amount of that maximum.

        vm.prank(EMSKI);
        dscEngine.mintStableCoin(amountToMint);

        uint256 engineBalanceBefore = wethToken.balanceOf(address(dscEngine));

        // Now, attempt to redeem a safe portion of collateral.
        uint256 redeemAmount = COLLATERAL_AMOUNT / 4;
        vm.prank(EMSKI);
        dscEngine.redeemCollateral(weth, redeemAmount);

        // Check that collateral deposited (tracked in DSCEngine) is reduced.
        uint256 remainingUsd = dscEngine.getCollateralDepositedInUsdForUser(EMSKI);
        uint256 expectedRemainingUsd = dscEngine.getUsdValueOfToken(weth, COLLATERAL_AMOUNT - redeemAmount);
        assertEq(remainingUsd, expectedRemainingUsd, "Collateral USD after redemption mismatch");

        // Check that EMSKI received redeemed tokens.
        uint256 emskiBalance = wethToken.balanceOf(EMSKI);
        uint256 expectedEmskiBalance = STARTING_WETH_BALANCE - COLLATERAL_AMOUNT + redeemAmount;
        assertEq(emskiBalance, expectedEmskiBalance, "Redeemed collateral not received by user");

        uint256 engineBalanceAfter = wethToken.balanceOf(address(dscEngine));
        assert(engineBalanceBefore > engineBalanceAfter);
    }

    function testRedeemCollateralFailsHealthFactor() public
        depositedCollateralAndMintedSC
    {
        uint256 engineBalanceBefore = wethToken.balanceOf(address(dscEngine));

        uint256 redeemAmount = COLLATERAL_AMOUNT;
        vm.prank(EMSKI);
        vm.expectRevert(DSCEngine.DSCEngine__NotEnoughCollateralDeposited.selector);
        dscEngine.redeemCollateral(weth, redeemAmount);
    }

    // redeemCollateralForStableCoin calls burnStableCoins and then redeemCollateral.
    function testRedeemCollateralForStableCoinSuccess() public
        depositedCollateralAndMintedSC
    {

        (uint256 mintAmount, uint256 tokensDepositedInUsd) = dscEngine.getAccountInfo(EMSKI);

        // EMSKI wants to reduce his debt by burning DSC and redeem some collateral.
        // LIKELY, the redemption amount is chosen such that health factor remains safe.
        uint256 burnAmount = 2e10;
        uint256 redeemCollateralAmount = dscEngine.getTokenAmountFromUsd(weth, burnAmount);

        // Before calling redeemCollateralForStableCoin, EMSKI must approve DSCEngine to transfer his DSC.
        vm.prank(EMSKI);
        stableCoin.approve(address(dscEngine), burnAmount);

        // Call redeemCollateralForStableCoi
        vm.prank(EMSKI);
        dscEngine.redeemCollateralForStableCoin(weth, redeemCollateralAmount, burnAmount);

        // Check that EMSKI’s minted DSC has decreased.
        (uint256 tokensMinted, ) = dscEngine.getAccountInfo(EMSKI);
        assertEq(tokensMinted, mintAmount - burnAmount, "Stable coin debt not reduced correctly");

        // Check that EMSKI received collateral (redeemed collateral should be transferred).
        uint256 emskiCollateralBalance = wethToken.balanceOf(EMSKI);
        uint256 expectedCollateralBalance = STARTING_WETH_BALANCE - COLLATERAL_AMOUNT + redeemCollateralAmount;
        assertEq(emskiCollateralBalance, expectedCollateralBalance, "Collateral redemption mismatch");
    }
    // --------------------------------------



    // ------ Burn stable coins tests ------
    function testBurnStableCoinsSuccess() public
        depositedCollateralAndMintedSC
    {
        (uint256 mintAmount, uint256 tokensDepositedInUsd) = dscEngine.getAccountInfo(EMSKI);

        // Approve DSCEngine to transfer stable coin from EMSKI.
        vm.prank(EMSKI);
        stableCoin.approve(address(dscEngine), mintAmount);

        // EMSKI burns a portion of his DSC.
        uint256 burnAmount = 300e18;
        vm.prank(EMSKI);
        dscEngine.burnStableCoins(burnAmount);

        // Check that stable coin balance of EMSKI is reduced.
        uint256 remainingBalance = stableCoin.balanceOf(EMSKI);
        assertEq(remainingBalance, mintAmount - burnAmount, "Stable coin not burned correctly");

        // Also check the account info.
        (uint256 tokensMinted, ) = dscEngine.getAccountInfo(EMSKI);
        assertEq(tokensMinted, mintAmount - burnAmount, "Minted token accounting mismatch");
    }

    function testBurnStableCoinsMoreThanMinted() public
        depositedCollateralAndMintedSC
    {
        (uint256 tokensMinted, ) = dscEngine.getAccountInfo(EMSKI);

        vm.prank(EMSKI);
        vm.expectRevert();
        dscEngine.burnStableCoins(tokensMinted + 1e18);
    }

    // ------ Liquidation tests ------

    modifier emskiCanBeLiquidated {
        // STEP 1: EMSKI deposits collateral and mints DSC such that his health factor is initially safe.
        uint256 mintAmount = 6000e18; // will be safe but at the bare minimum (if ETH Price drop below 2k USD -> UNSAFE)
        vm.prank(EMSKI);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.prank(EMSKI);
        dscEngine.depositCollateralAndMintStableCoin(weth, COLLATERAL_AMOUNT, mintAmount);


        // STEP 2: Simulate a price drop for WETH below 2k USD so that EMSKI becomes undercollateralized.
        MockV3Aggregator aggregator = MockV3Aggregator(wethPricefeed);
        aggregator.updateAnswer(2000e8);
        // At this point, EMSKI’s health factor should drop below MIN_HEALTH_FACTOR.
        // EMSKI should have maximum 5k tokens = (COLLATERAL_AMOUNT * PRICE) / 2;
        _;
    }

    // Test that calling liquidate on a healthy user reverts.
    function testLiquidateRevertsWhenUserHealthy() public
        depositedCollateralAndMintedSC
    {
        // LIQUIDATOR prepares (deposit collateral and mint some DSC to have a defined health factor).
        uint256 liqMint = 1000e18;
        vm.prank(LIQUIDATOR);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.prank(LIQUIDATOR);
        dscEngine.depositCollateralAndMintStableCoin(weth, COLLATERAL_AMOUNT, liqMint);

        // LIQUIDATOR approves DSCEngine to transfer his DSC tokens.
        vm.prank(LIQUIDATOR);
        stableCoin.approve(address(dscEngine), liqMint);

        // Since EMSKI is healthy, liquidate should revert.
        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__UserHealthFactorOk.selector);
        dscEngine.liquidate(weth, EMSKI, 50e18);
    }

    // Test a successful liquidation scenario.
    function testLiquidateSuccess() public
        emskiCanBeLiquidated
    {
        (uint256 emskiMintAmount, ) = dscEngine.getAccountInfo(EMSKI);

        // STEP 1: LIQUIDATOR prepares by depositing collateral and minting DSC so his health factor is defined.
        uint256 liqMint = 2000e18;
        uint256 liqCollateralAmount = 10 * COLLATERAL_AMOUNT;

        vm.prank(LIQUIDATOR);
        wethToken.approve(address(dscEngine), liqCollateralAmount);
        vm.prank(LIQUIDATOR);
        dscEngine.depositCollateralAndMintStableCoin(weth, liqCollateralAmount, liqMint);
        vm.prank(LIQUIDATOR);
        stableCoin.approve(address(dscEngine), liqMint);

        uint256 initialLiquidaterBalance = wethToken.balanceOf(LIQUIDATOR);

        // STEP 2: LIQUIDATOR liquidates EMSKI.
        uint256 debtToCover = 1000e18; // Debt to cover in stable coins which will be burnt from the EMSKIQ's account
        vm.prank(LIQUIDATOR);
        dscEngine.liquidate(weth, EMSKI, debtToCover);

        // Check that EMSKI’s minted DSC has decreased by debtToCover.
        (uint256 tokensMintedAfter, ) = dscEngine.getAccountInfo(EMSKI);
        assertEq(tokensMintedAfter, emskiMintAmount - debtToCover, "Debt not reduced correctly after liquidation");

        // Check that LIQUIDATOR received collateral.
        uint256 liqWethBalance = wethToken.balanceOf(LIQUIDATOR);
        uint256 tokenAmt = dscEngine.getTokenAmountFromUsd(weth, debtToCover);
        uint256 bonus = (tokenAmt * 10) / 100;  // LIQUIDATION_BONUS is 10%
        uint256 expectedCollateral = initialLiquidaterBalance + tokenAmt + bonus;
        assertEq(liqWethBalance, expectedCollateral, "Liquidator did not receive correct collateral amount");
    }

    /// @notice Should revert if liquidation does not improve the insolvent user’s health factor.
    function testLiquidateFailsIfHealthFactorNotImprovedBadWeather() public
        emskiCanBeLiquidated
    {
        // LIQUIDATOR prepares.
        uint256 liqMint = 1000e18;
        vm.prank(LIQUIDATOR);
        wethToken.approve(address(dscEngine), COLLATERAL_AMOUNT);
        vm.prank(LIQUIDATOR);
        dscEngine.depositCollateralAndMintStableCoin(weth, COLLATERAL_AMOUNT, liqMint);
        vm.prank(LIQUIDATOR);
        stableCoin.approve(address(dscEngine), liqMint);

        // Attempt liquidation with a very small debtToCover that does not improve EMSKI's health factor.
        uint256 smallDebtToCover = 1e18;
        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__UserHealthFactorNotImproved.selector);
        dscEngine.liquidate(weth, EMSKI, smallDebtToCover);
    }


    // --- Health factor tests ---
}
