// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {PlatformToken} from "./PlatformToken.sol";

/// @title CrowdfundingPlatform
///
/// @author Emil Tsanev
///
/// @notice Main contract handling funding of a new project and then distibuting
///         awards to the contributors based on their investment.
contract CrowdfundingPlatform is Ownable, ReentrancyGuard {
    /// EVENTS
    event CampaignCreated(uint256 indexed campaignId, address indexed campaignCreator);
    event CampaignFunded(uint256 indexed campaignId, address indexed contributor, uint256 fundingAmount);
    event CampaignFailed(uint256 indexed campaignId, address indexed finalizer, uint256 award);
    event CampaignSucceeded(uint256 indexed campaignId);
    event CampaignContributorAwarded(uint256 indexed campaignId, address indexed contributor, uint256 award);

    /// ERRORS
    error CrowdfundingPlatform__CampaignAlreadyExists();
    error CrowdfundingPlatform__CampaignIdNotFound();
    error CrowdfundingPlatform__CampaignNotActive();
    error CrowdfundingPlatform__InsufficientInvestAmount();
    error CrowdfundingPlatform__CampaignDurationToShort();
    error CrowdfundingPlatform__CampaignDeadlineReached();
    error CrowdfundingPlatform__DeadlineNotReached();
    error CrowdfundingPlatform__CampaignNotReachedFundingGoal();
    error CrowdfundingPlatform__NotAContributorInCampaign();
    error CrowdfundingPlatform__InsufficientLaunchFeePassed();
    error CrowdfundingPlatform__FinalizeAwardMustBeMoreThanLaunchFee();

    /// TYPE DECLARATIONS
    enum CampaignState {
        Active,
        Succeeded,
        Failed
    }

    struct Campaign {
        address creator;
        string name;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 deadline;
        address[] contributors;
        mapping(address contributor => uint256 fundInvested) contributorsInvestments;
        CampaignState currentState;
    }

    /// STATE VARIABLES
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MINIMAL_INVESTMENT = 0.0420 ether;
    uint256 private constant LAUNCH_FEE = 0.001 ether;
    uint256 private constant FINALIZE_PENALTY = 0.0001 ether;
    uint256 private constant MIN_CAMPAIGN_DURATION = 1 days;


    PlatformToken private immutable i_platformToken;

    mapping (uint256 campaignID=>Campaign) private s_campaigns;
    uint256[] private s_campaignIds;
    uint256 private campaignsCounter;

    uint256 private s_ethToTokenRatio;
    uint256 private s_finalizeAward;

    /// MODIFIERS
    modifier campaignValid(uint256 campaignId) {
        if (campaignId >= campaignsCounter) {
            revert CrowdfundingPlatform__CampaignIdNotFound();
        }
        _;
    }

    modifier campaignValidAndActive(uint256 campaignId) {
        if (campaignId >= campaignsCounter) {
            revert CrowdfundingPlatform__CampaignIdNotFound();
        }
        if (s_campaigns[campaignId].currentState != CampaignState.Active) {
            revert CrowdfundingPlatform__CampaignNotActive();
        }
        _;
    }


    /// ------------------------
    /// -- EXTERNAL FUNCTIONS --
    /// ------------------------

    /// @notice Constructor
    ///
    /// @param platformToken an ERC20Burnable/PlatformToken Implementation for the native platformToken
    /// @param initialRatio The initial ETH-to-token ratio (with 18 decimals).
    constructor(PlatformToken platformToken, uint256 initialRatio, uint256 finalizeAward) Ownable(msg.sender) {
        i_platformToken = platformToken;
        campaignsCounter = 0;
        s_ethToTokenRatio = initialRatio;

        if (finalizeAward < (LAUNCH_FEE * s_ethToTokenRatio) / PRECISION) {
            revert CrowdfundingPlatform__FinalizeAwardMustBeMoreThanLaunchFee();
        }
        s_finalizeAward = finalizeAward;
    }


    /// @notice Launch new campaign with its corresponding name and fundingGoal
    ///
    /// @dev Every campaing has its dedicated campaign ID, which for now is just a
    ///      counter that is being incremented on every new launched campaign
    /// @dev The campaign creator must pay exactly the LAUNCH_FEE amount when launching a campaign.
    ///
    /// @param campaignName the campaign name (e.g. TrumpCoin)
    /// @param fundingGoal the funding goal that this campaign needs to be considered as SUCCESS
    ///
    /// @return campaignId the unique campaign ID that identifies a campaign
    function launchCampaign(string calldata campaignName, uint256 fundingGoal, uint256 duration) 
        public
        payable
        returns(uint256 campaignId)
    {
        if (msg.value != LAUNCH_FEE) {
            revert CrowdfundingPlatform__InsufficientLaunchFeePassed();
        }

        Campaign storage newCampaign = s_campaigns[campaignsCounter];

        if (newCampaign.creator != address(0)) {
            revert CrowdfundingPlatform__CampaignAlreadyExists();
        }

        if (duration < MIN_CAMPAIGN_DURATION) {
            revert CrowdfundingPlatform__CampaignDurationToShort();
        }
        
        newCampaign.creator = msg.sender;
        newCampaign.fundingGoal = fundingGoal;
        newCampaign.name = campaignName;
        newCampaign.currentState = CampaignState.Active;
        newCampaign.deadline = block.timestamp + duration;
        newCampaign.currentFunding = 0;
         
        campaignId = campaignsCounter;
        campaignsCounter++;
        emit CampaignCreated(campaignId, msg.sender);
    }


    /// @notice Funding a campaign by its unique campaign ID
    ///         If the campaign does not exist or isn't active the transaction will be reverted.
    ///
    /// @param campaignId the campaignID unique identifier
    function fundCampaign(uint256 campaignId)
        external
        payable
        campaignValidAndActive(campaignId)
        nonReentrant
    {
        if (msg.value <= MINIMAL_INVESTMENT) {
            revert CrowdfundingPlatform__InsufficientInvestAmount();
        }
        
        Campaign storage campaign = s_campaigns[campaignId];
        if (campaign.deadline <= block.timestamp) {
            revert CrowdfundingPlatform__CampaignDeadlineReached();
        }

        if (campaign.contributorsInvestments[msg.sender] == 0) {
            campaign.contributors.push(msg.sender);
        }
        campaign.contributorsInvestments[msg.sender] += msg.value;
        campaign.currentFunding += msg.value;

        emit CampaignFunded(campaignId, msg.sender, msg.value);

        if (campaign.fundingGoal <= campaign.currentFunding) {
            _campaignSucceeded(campaignId);
        }
    }

    /// @notice Finalize a campaign once its deadline has passed.
    ///         Anyone can call this function. The caller receives a small incentive fee.
    ///         If campaign has failed, the corresponding token amount is "burned".
    ///
    /// @dev When the funds raised are below minumum we are burning the raised tokens
    ///      and mint (launch fee * ethereum to token ration) to the finalizer
    ///
    /// @param campaignId The campaign's unique identifier.
    function finalizeCampaign(uint256 campaignId) 
        external
        campaignValidAndActive(campaignId)
        nonReentrant
    {
        Campaign storage campaign = s_campaigns[campaignId];

        if (block.timestamp < campaign.deadline) {
            revert CrowdfundingPlatform__DeadlineNotReached();
        }

        uint256 award;
        uint256 totalFundsRaisedInTokens = (campaign.currentFunding * s_ethToTokenRatio) / PRECISION;

        if (totalFundsRaisedInTokens < s_finalizeAward) {
            // XXX: Causing some mismatch of minted/burned tokens but at least the campaign launcher has payed for this newly minted tokens
            award = (LAUNCH_FEE * s_ethToTokenRatio - FINALIZE_PENALTY) / PRECISION;
        } else {
            award = s_finalizeAward;
        }

        campaign.currentState = CampaignState.Failed;

        if (award > 0) {
            i_platformToken.mint(msg.sender, award);
        }

        emit CampaignFailed(campaignId, msg.sender, award);
    }

    function setTokenRatio(uint256 ratio) external onlyOwner {
        s_ethToTokenRatio = ratio;
    }

    function setFinalizeAward(uint256 award) external onlyOwner {
        if (award < (LAUNCH_FEE * s_ethToTokenRatio) / PRECISION) {
            revert CrowdfundingPlatform__FinalizeAwardMustBeMoreThanLaunchFee();
        }

        s_finalizeAward = award;
    }

    /// ------------------------
    /// -- INTERNAL FUNCTIONS --
    /// ------------------------

    /// @notice Internal function called upon a successful campaign.
    ///         It mints platform tokens to each contributor based on their ETH investment.
    ///         The minted amount is calculated dynamically using the base ratio.
    ///
    /// @param campaignId The campaign's unique identifier.
    function _campaignSucceeded(uint256 campaignId) 
        internal
        campaignValidAndActive(campaignId)
    {
        Campaign storage campaign = s_campaigns[campaignId];

        if (campaign.fundingGoal > campaign.currentFunding) {
            revert CrowdfundingPlatform__CampaignNotReachedFundingGoal();
        }

        campaign.currentState = CampaignState.Succeeded;
        
        for (uint256 i = 0; i < campaign.contributors.length; i++) {
            _awardContributor(campaignId, campaign.contributors[i]);
        }

        emit CampaignSucceeded(campaignId);
    }

    /// @notice Internal function called for awaring a contributor to a campaign
    ///         It mints platform tokens to that specific contributor based on their ETH investment.
    ///
    /// @param campaignId The campaign's unique identifier.
    /// @param contributor The contributor address for that campaign
    function _awardContributor(uint256 campaignId, address contributor) 
        internal
        campaignValid(campaignId)
    {
        Campaign storage campaign = s_campaigns[campaignId];

        if (campaign.contributorsInvestments[contributor] == 0) {
            revert CrowdfundingPlatform__NotAContributorInCampaign();
        }

        uint256 fundsInvested = campaign.contributorsInvestments[contributor];
        uint256 award = (fundsInvested * s_ethToTokenRatio) / PRECISION;
        i_platformToken.mint(contributor, award);

        emit CampaignContributorAwarded(campaignId, contributor, award);
    }

    /// -----------------
    /// ---- GETTERS ----
    /// -----------------

    function getCampaignName(uint256 campaignId) 
        view
        public
        returns (string memory)
    {
        return s_campaigns[campaignId].name;
    }

    function getCampaignFundingGoal(uint256 campaignId) 
        view
        public
        returns (uint256)
    {
        return s_campaigns[campaignId].fundingGoal;
    }

    function getCampaignCurrentFunding(uint256 campaignId) 
        view
        public
        returns (uint256)
    {
        return s_campaigns[campaignId].currentFunding;
    }

    function getCampaignCreator(uint256 campaignId) 
        view
        public
        returns (address)
    {
        return s_campaigns[campaignId].creator;
    }

    function getCampaignState(uint256 campaignId) 
        view
        public
        returns (CampaignState)
    {
        return s_campaigns[campaignId].currentState;
    }

    function isContributorInCampaign(uint256 campaignId) 
        view
        public
        returns (bool)
    {
        return s_campaigns[campaignId].contributorsInvestments[msg.sender] != 0;
    }

    function getMinimalInvestment() pure public returns(uint256) {
        return MINIMAL_INVESTMENT;
    }

    function getLaunchFee() pure public returns(uint256) {
        return LAUNCH_FEE;
    }

    function getFinalizePenalty() pure public returns(uint256) {
        return FINALIZE_PENALTY;
    }

    function getEthToTokenRatio() view public returns(uint256) {
        return s_ethToTokenRatio;
    }

    function getFinalizeAward() view public returns(uint256) {
        return s_finalizeAward;
    }
}
