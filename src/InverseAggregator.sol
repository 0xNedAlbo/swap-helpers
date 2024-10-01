// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IAggregator } from "./interfaces/chainlink/IAggregator.sol";

contract InverseAggregator is IAggregator {
    IAggregator public immutable priceFeed;
    uint8 public immutable decimals;

    constructor(address priceFeedAddress) {
        priceFeed = IAggregator(priceFeedAddress);
        decimals = priceFeed.decimals();
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = 0;
        startedAt = 0;
        answeredInRound = 0;
        (, int256 originAnswer,, uint256 originUpdatedAt,) = priceFeed.latestRoundData();
        answer = int256(10 ** decimals) / (originAnswer * int256(10 ** decimals));
        updatedAt = originUpdatedAt;
    }

    /* solhint-disable */
    function description() external pure override returns (string memory) {
        revert("not implemented");
    }

    function version() external pure override returns (uint256) {
        revert("not implementd");
    }

    function getRoundData(uint80) external pure override returns (uint80, int256, uint256, uint256, uint80) {
        revert("not implemented");
    }
    /* solhint-enable */
}
