// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract SwapMath {
    uint256 BPS = 10_000;

    function sellSlippage(uint256 expected, uint256 actual, uint256 maxBps) public pure returns (uint256) {
        if (actual >= expected) return 0;
        return (expected - actual) * maxBps / expected;
    }

    function buySlippage(uint256 expected, uint256 actual, uint256 maxBps) public pure returns (uint256) {
        if (actual <= expected) return 0;
        return (actual - expected) * maxBps / expected;
    }

    function slippage(uint256 expected, uint256 actual) public view returns (int256) {
        require(expected > 0, "expected cannot be zero");
        if (actual >= expected) return int256((actual - expected) * BPS / expected);
        return -int256((expected - actual) * BPS / expected);
    }
}
