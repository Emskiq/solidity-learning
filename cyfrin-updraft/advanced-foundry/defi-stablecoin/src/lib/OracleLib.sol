// SPDX-Licnse-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";


/*
 * @title OracleLib
 * @author Emil Tsanev
 *
 * This library is checking whether the oracle price is stale/not updated recently
 * If the price is stale, we would like to stop the functionality of DSCEngine.
 *
 * @notice If ChainLink oracle brokes -> The funds locked in the protocol are at risk
 */
library OracleLib {

    error OracleLib__OraclePriceIsStale();

    uint256 private constant TIMEOUT = 3 hours;

    function stalePriceCheck(AggregatorV3Interface priceFeed) public view 
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();

        uint256 secondSinceLastUpdate = block.timestamp - updatedAt;
        if (secondSinceLastUpdate > TIMEOUT) {
            revert OracleLib__OraclePriceIsStale();
        }

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}
