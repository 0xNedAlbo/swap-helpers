// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IAggregator {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}
