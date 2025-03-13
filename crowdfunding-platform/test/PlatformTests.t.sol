// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {CrowdfundingPlatform} from "src/CrowdfundingPlatform.sol";
import {PlatformToken} from "src/PlatformToken.sol";
import {DeployPlatform} from "script/DeployPlatform.s.sol";

contract PlatformTests is Test {

    DeployPlatform deployer;

    PlatformToken token;
    CrowdfundingPlatform platform;

    // This address is used for simulating external calls.
    address USER1 = makeAddr("USER1");
    address USER2 = makeAddr("USER2");

    uint256 campaignId;
    uint256 launchFee;
    uint256 penalty;

    uint256 constant CAMPAIGN_FUNDING_GOAL = 5 ether;
    uint256 constant FUNDS_AMOUNT = 15 ether;
    uint256 constant CAMPAIGN_DURATION = 2 days;

    uint256 private constant PRECISION = 1e18;

    function setUp() public {
        deployer = new DeployPlatform();
        (platform, token) = deployer.run();

        launchFee = platform.getLaunchFee();
        penalty = platform.getFinalizePenalty();

        // Fund user1 and user2 with some ETH for testing.
        vm.deal(USER1, FUNDS_AMOUNT);
        vm.deal(USER2, FUNDS_AMOUNT);
    }

    // --------------------
    //  Basic Set/Get Tests
    // --------------------

    function testGetMinimalInvestment() public view {
        uint256 minInvestment = platform.getMinimalInvestment();
        // Compare with your known constant
        assertEq(minInvestment, 0.0420 ether, "Should match the MINIMAL_INVESTMENT constant");
    }

    function testSetTokenRatioByOwner() public {
        platform.setTokenRatio(12345);
        assertEq(platform.getEthToTokenRatio(), 12345);
    }

    function testSetTokenRatioByNonOwnerReverts() public {
        vm.prank(USER1);
        vm.expectRevert();
        platform.setTokenRatio(99999);
    }

    function testSetFinalizeAwardAsNonOwnerReverts() public {
        vm.prank(USER1);
        vm.expectRevert();
        platform.setFinalizeAward(12345678);
    }

    function testSetFinalizeAwardBelowMinimumReverts() public {
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__FinalizeAwardMustBeMoreThanLaunchFee.selector);
        platform.setFinalizeAward(69);
    }

    function testIsContributorInCampaignNonExistent() public {
        // For a non-existent campaign, there's no revert, 
        // but the function should see a default struct => 0 investment => false
        bool isContributor = platform.isContributorInCampaign(69);
        assertFalse(isContributor, "Should be false for non-existent campaign");
    }


    // -----------------
    //  Campaign Tests
    // -----------------

    function testLaunchCampaignSuccess() public {
        string memory campaignName = "Test Campaign";
        campaignId = platform.launchCampaign{value: launchFee}(campaignName, CAMPAIGN_FUNDING_GOAL, CAMPAIGN_DURATION);

        // Validate that the campaign was created successfully.
        assertEq(keccak256(bytes(platform.getCampaignName(campaignId))), keccak256(bytes(campaignName)));
        assertEq(platform.getCampaignFundingGoal(campaignId), CAMPAIGN_FUNDING_GOAL);
        assertEq(platform.getCampaignCreator(campaignId), address(this), "Creator should match the caller of launchCampaign");
        assertEq(uint256(platform.getCampaignState(campaignId)), uint256(CrowdfundingPlatform.CampaignState.Active));
    }

    function testLaunchCampaignFailsForShortDuration() public {
        string memory campaignName = "Test Campaign";
        uint256 duration = 12 hours; // below the minimum of 1 day
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__CampaignDurationToShort.selector);
        platform.launchCampaign{value: launchFee}(campaignName, CAMPAIGN_FUNDING_GOAL, duration);
    }

    function testLaunchCampaignNoLauncFee() public {
        string memory campaignName = "Test Campaign";
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__InsufficientLaunchFeePassed.selector);
        campaignId = platform.launchCampaign(campaignName, CAMPAIGN_FUNDING_GOAL, CAMPAIGN_DURATION);
    }

    // assumes that the campaignId will be 0
    modifier campaignLaunched() {
        string memory campaignName = "EMSKIQQQ";
        campaignId = platform.launchCampaign{value: launchFee}(campaignName, CAMPAIGN_FUNDING_GOAL, CAMPAIGN_DURATION);
        _;
    }

    function testFundCampaignSuccess()
        public
        campaignLaunched
    {
        uint256 investAmount = 1 ether;
        vm.prank(USER1);
        platform.fundCampaign{value: investAmount}(campaignId);

        // Check that the campaign's funding was updated.
        assertEq(platform.getCampaignCurrentFunding(campaignId), investAmount);
        
        vm.prank(USER1);
        bool isContributor = platform.isContributorInCampaign(campaignId);
        assertTrue(isContributor, "User1 should be a contributor now");
    }

    function testFundCampaignWithBelowMinimalInvestment()
        public
        campaignLaunched
    {
        uint256 investAmount = 0.001 ether;
        vm.prank(USER1);
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__InsufficientInvestAmount.selector);
        platform.fundCampaign{value: investAmount}(campaignId);
    }

    function testFundCampaignInvalidId() public {
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__CampaignIdNotFound.selector);
        platform.fundCampaign{value: 1 ether}(420);
    }


    function testFundCampaignFailsIfDeadlinePassed() 
        public
        campaignLaunched
    {
        // Warp time to after the deadline.
        vm.warp(block.timestamp + 2 days);

        uint256 investAmount = 1 ether;
        vm.prank(USER1);
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__CampaignDeadlineReached.selector);
        platform.fundCampaign{value: investAmount}(campaignId);
    }

    function testFinalizeCampaignBeforeDeadlineFails()
        public
        campaignLaunched
    {
        // Try finalizing before the deadline.
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__DeadlineNotReached.selector);
        platform.finalizeCampaign(campaignId);
    }

    function testFinalizeCampaignInvalidId() public {
        // No campaign with ID 9999
        vm.expectRevert(CrowdfundingPlatform.CrowdfundingPlatform__CampaignIdNotFound.selector);
        platform.finalizeCampaign(9999);
    }

    // Test finalization when no funding is raised.
    function testFinalizeCampaignWithNoFunding() public campaignLaunched {
        uint256 tokenBalanceUser1Start = token.balanceOf(USER1);

        uint256 ratio = platform.getEthToTokenRatio();
        uint256 user1ExpectedAward = (launchFee * ratio - penalty) / PRECISION;

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);

        vm.expectEmit(true, true, false, true, address(platform));
        emit CampaignFailed(campaignId, USER1, user1ExpectedAward);

        // Ensure finalizer is not the campaign creator.
        vm.prank(USER1);
        platform.finalizeCampaign(campaignId);

        uint256 tokenBalanceUser1End = token.balanceOf(USER1);

        assertEq(uint256(platform.getCampaignState(campaignId)), uint256(CrowdfundingPlatform.CampaignState.Failed));
        assertEq(tokenBalanceUser1Start, 0);
        assertEq(tokenBalanceUser1End, user1ExpectedAward);
    }

    // Test finalization when funding is raised above s_finalizeAward.
    function testFinalizeCampaignHighFunding() public campaignLaunched {
        // Fund with enough so that total tokens >= s_finalizeAward.
        uint256 investAmount = 3 ether; // Assume this converts to more than s_finalizeAward tokens.
        vm.prank(USER1);
        platform.fundCampaign{value: investAmount}(campaignId);

        vm.warp(block.timestamp + CAMPAIGN_DURATION + 1);

        vm.prank(USER2);
        platform.finalizeCampaign(campaignId);

        uint256 expectedAward = platform.getFinalizeAward();

        uint256 finalizerBalance = token.balanceOf(USER2);
        console.log("Finalizer Award:", finalizerBalance);
        assertEq(finalizerBalance, expectedAward);
        assertEq(uint256(platform.getCampaignState(campaignId)), uint256(CrowdfundingPlatform.CampaignState.Failed));
    }

    // This test simulates a successful campaign by funding above the goal,
    function testFundCampaignTillSuccess()
        public
        campaignLaunched
    {
        uint256 tokenBalanceUser1Start = token.balanceOf(USER1);
        uint256 tokenBalanceUser2Start = token.balanceOf(USER2);

        assertEq(tokenBalanceUser1Start, 0);
        assertEq(tokenBalanceUser2Start, 0);

        uint256 user1Contribution = 3 ether;
        uint256 user2Contribution = 2 ether;
        uint256 ratio = platform.getEthToTokenRatio();

        uint256 user1ExpectedAward = (user1Contribution * ratio) / PRECISION;
        uint256 user2ExpectedAward = (user2Contribution * ratio) / PRECISION;

        // Simulate funding by user1 and user2

        vm.prank(USER1);

        // xxx: just checking the correct events also
        vm.expectEmit(true, true, false, true);
        emit CampaignFunded(campaignId, USER1, user1Contribution);
        platform.fundCampaign{value: user1Contribution}(campaignId);

        vm.prank(USER2);
        platform.fundCampaign{value: user2Contribution}(campaignId);

        assertEq(uint256(platform.getCampaignState(campaignId)), uint256(CrowdfundingPlatform.CampaignState.Succeeded));

        uint256 tokenBalanceUser1End = token.balanceOf(USER1);
        uint256 tokenBalanceUser2End = token.balanceOf(USER2);

        assertEq(tokenBalanceUser1End, user1ExpectedAward);
        assertEq(tokenBalanceUser2End, user2ExpectedAward);
    }

    // Event declarations for expectEmit (mirroring events in the contract)
    event CampaignCreated(uint256 indexed campaignId, address indexed campaignCreator);
    event CampaignFunded(uint256 indexed campaignId, address indexed contributor, uint256 fundingAmount);
    event CampaignFailed(uint256 indexed campaignId, address indexed finalizer, uint256 award);
    event CampaignSucceeded(uint256 indexed campaignId);
    event CampaignContributorAwarded(uint256 indexed campaignId, address indexed contributor, uint256 award);

}
