// SPDX-Licnse-Identifier: MIT
pragma solidity ^0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {StableCoin} from "./StableCoin.sol";

import {OracleLib} from "./lib/OracleLib.sol";


/*
 * @title DSCEngine
 * @author Emil Tsanev
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 *
 */
contract DSCEngine is ReentrancyGuard {
    error DSCEngine__AmountShouldBeMoreThanZero();
    error DSCEngine__TokenAddressAndPriceFeedsAddressNotEqualLen();
    error DSCEngine__TransferFailed();
    error DSCEngine__MintFailed();
    error DSCEngine__NotAllowedTokenCollateral();
    error DSCEngine__NotEnoughCollateralDeposited();
    error DSCEngine__UserHealthFactorOk();
    error DSCEngine__UserHealthFactorNotImproved();

    // Types:
    using OracleLib for AggregatorV3Interface;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount);

    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10; // percent

    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant MIN_HEALTH_FACTOR = 100;

    StableCoin private immutable i_stableCoin;

    mapping(address token => address priceFeed) private s_priceFeeds;
    address[] private s_tokenCollateralAddress;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amount) private s_stableCoinMinted;


    // ---- Modifiers ----
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__AmountShouldBeMoreThanZero();
        }
        _;
    }

    modifier allowedCollateralToken(address tokenAddress) {
        if (s_priceFeeds[tokenAddress] == address(0)) {
            revert DSCEngine__NotAllowedTokenCollateral();
        }
        _;
    }


    // ---- Constuctor ----
    constructor(address[] memory tokenCollateralAddress,
                address[] memory priceFeeds)
    {
        // fill the priceFeeds map (chainlink price feeds pbly)
        if (tokenCollateralAddress.length != priceFeeds.length) {
            revert DSCEngine__TokenAddressAndPriceFeedsAddressNotEqualLen();
        }

        for (uint256 i = 0; i < tokenCollateralAddress.length; i++) {
            s_priceFeeds[tokenCollateralAddress[i]] = priceFeeds[i];
        }

        s_tokenCollateralAddress = tokenCollateralAddress;

        i_stableCoin = new StableCoin(address(this));
    }


    // ---- External Functions ----
    /*
     * @param amountToMint: The amount of Stable coin you want to mint
     * You can only mint DSC if you have enough collateral
     */
    function mintStableCoin(uint256 amountToMint) public
        moreThanZero(amountToMint)
        nonReentrant
    {
        s_stableCoinMinted[msg.sender] += amountToMint;
        _revertIfHealthFactorIsBroken(msg.sender); // revert if it is broken

        bool minted = i_stableCoin.mint(msg.sender, amountToMint);
        if (minted != true) {
            revert DSCEngine__MintFailed();
        }
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     * @param mintCoinAmount: The amount of stable coin that user would like to mint
     */
    function depositCollateralAndMintStableCoin(address tokenCollateral,
                                                uint256 amountCollateral,
                                                uint256 mintCoinAmount) external
    {
        depositCollateral(tokenCollateral, amountCollateral);
        mintStableCoin(mintCoinAmount);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral you're depositing
     */
    function depositCollateral(address tokenCollateralAddress, uint256 amount) public
        // checks:
        moreThanZero(amount)
        allowedCollateralToken(tokenCollateralAddress)
        nonReentrant
    {
        // effect
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amount;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amount);

        // interaction
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForStableCoin(
        address tokenCollateralAddress,
        uint256 collateralAmount,
        uint256 amountToBurn) external
    {
        _burnStableCoins(amountToBurn, msg.sender, msg.sender);
        _redeemCollateral(tokenCollateralAddress, collateralAmount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /*
     *
     */
    function redeemCollateral(address tokenCollateralAddr, uint256 amount) public
        // checks
        moreThanZero(amount)
        nonReentrant
    {
        _redeemCollateral(tokenCollateralAddr, amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    /*
     * @param collateral: The ERC20 token address of the collateral you're using to make the protocol solvent again.
     * This is collateral that you're going to take from the user who is insolvent.
     * In return, you have to burn your DSC to pay off their debt, but you don't pay off your own.
     * @param user: The user who is insolvent. They have to have a _healthFactor below MIN_HEALTH_FACTOR
     * @param debtToCover: The amount of DSC you want to burn to cover the user's debt.
     *
     * @notice: You can partially liquidate a user.
     * @notice: You will get a 10% LIQUIDATION_BONUS for taking the users funds.
     *
     * @notice: This function working assumes that the protocol
     *          will be roughly 150% overcollateralized in order for this to work.
     *
     * @notice: A known bug would be if the protocol was only 100% collateralized,
     *          we wouldn't be able to liquidate anyone.
     *
     * For example, if the price of the collateral plummeted before anyone could be liquidated.
     */
     function liquidate(address collateral, address user, uint256 debtToCover) external
        moreThanZero(debtToCover)
        allowedCollateralToken(collateral)
        nonReentrant
    {
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__UserHealthFactorOk();
        }

        // burn thier stable coin debt and take their collateral

        // calculate their stable coin debt (to burn)
        // calculate how much collateral can be took

        // Example:
        // Bad user = 140$ ETH and 100$ stable coin
        // => 200$ should be deposited not 140..

        
        // If covering 100 DSC, we need to $100 of collateral
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);

        uint256 bonus = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;

        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonus;

        _redeemCollateral(collateral, totalCollateralToRedeem, user, msg.sender);
        _burnStableCoins(debtToCover, user, msg.sender);

        uint256 endingHealthFactor = _healthFactor(user);

        if (endingHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__UserHealthFactorNotImproved();
        }

        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function getHealthFactor(address user) external view returns(uint256) {
        return _healthFactor(user);
    }

    function burnStableCoins(uint256 amount) public
        moreThanZero(amount)
    {
        _burnStableCoins(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender);
    }


    // ---- Internal & Private functions ----
    function _healthFactor(address user) private view returns(uint256) {
        (uint256 tokensMinted, uint256 collateralDepositedInUsd) = _accountInfo(user);
        return calculateHealthFactor(tokensMinted, collateralDepositedInUsd);
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 healthFactor =  _healthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__NotEnoughCollateralDeposited();
        }
    }

    function _accountInfo(address user) internal view returns(uint256 tokenMinted, uint256 collateralDepositedInUsd) {
        tokenMinted = s_stableCoinMinted[user];
        collateralDepositedInUsd = getCollateralDepositedInUsdForUser(user);
    }

    function _redeemCollateral(address tokenCollateralAddr, uint256 amount, address from, address to) internal
        // checks
        moreThanZero(amount)
    {
        // effects
        s_collateralDeposited[from][tokenCollateralAddr] -= amount;
        emit CollateralRedeemed(from, to, tokenCollateralAddr, amount);

        // interaction
        bool success = IERC20(tokenCollateralAddr).transfer(to, amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function _burnStableCoins(uint256 amount, address onBehalfOf, address dscFrom) public
        moreThanZero(amount)
    {
        s_stableCoinMinted[onBehalfOf] -= amount;

        bool success = i_stableCoin.transferFrom(dscFrom, address(this), amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }

        i_stableCoin.burn(amount);
    }

    // ---- Public VIEW functions ----
    function getCollateralDepositedInUsdForUser(address user) public view returns(uint256 collateralValueInUsd) {
        collateralValueInUsd = 0;

        for (uint256 i = 0; i < s_tokenCollateralAddress.length; i++) {
            address token = s_tokenCollateralAddress[i];
            uint256 amount = s_collateralDeposited[user][token];
            collateralValueInUsd += getUsdValueOfToken(token, amount);
        }
    }

    // ----------------------------------------------------------------------
    function getUsdValueOfToken(address token, uint256 amount) public view returns(uint256 valueInUsd) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.stalePriceCheck();
        valueInUsd = (uint256(price) * ADDITIONAL_FEED_PRECISION * amount) / PRECISION;
    }

    // ----------------------------------------------------------------------
    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns(uint256 valueInUsd) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.stalePriceCheck();
        valueInUsd = ((usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }

    // ----------------------------------------------------------------------
    function getStableCoinAddress() public view returns(address) {
        return address(i_stableCoin);
    }

    // ----------------------------------------------------------------------
    function getAccountInfo(address user) public view returns(uint256 tokenMinted, uint256 collateralDepositedInUsd) {
        return _accountInfo(user);
    }

    // ----------------------------------------------------------------------
    function getCollateralsAdrresses() public view returns(address[] memory) {
        return s_tokenCollateralAddress;
    }

    // ----------------------------------------------------------------------
    function getCollateralsBalanceForUser(address user, address collateral) external view returns(uint256) {
        return s_collateralDeposited[user][collateral];
    }

    // ----------------------------------------------------------------------
    function getMinHealthFactor() external view returns(uint256) {
        return MIN_HEALTH_FACTOR;
    }

    // ----------------------------------------------------------------------
    function calculateHealthFactor(uint256 tokensMinted, uint256 collateralDepositedInUsd) public view returns(uint256) {
        if (tokensMinted == 0) {
            return type(uint256).max;
            // debatable what should be done here a default value of zero?
        }

        // basically deviding the collateral deposited by 2
        uint256 collateralAdjusted = (LIQUIDATION_THRESHOLD * collateralDepositedInUsd) / LIQUIDATION_PRECISION;

        // so now we got to devide collateralAdjusted / tokenMinted -> get the ratio Collateral/Tokens >= 2
        // or since se have already devided the collateral = CollateralAdjusted by 2 => CollateralAdjusted/Tokens >= 1
        return (collateralAdjusted * LIQUIDATION_PRECISION) / tokensMinted;
    }

    // ----------------------------------------------------------------------
    function getCollateralPriceFeed(address collatteral) public view returns(address) {
        return s_priceFeeds[collatteral];
    }
}
