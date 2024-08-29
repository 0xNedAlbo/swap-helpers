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

    function latestAnswer() external view override returns (int256) {
        return int256(10 ** decimals) / (priceFeed.latestAnswer() * int256(10 ** decimals));
    }

    function latestTimestamp() external view override returns (uint256) {
        return priceFeed.latestTimestamp();
    }
}
