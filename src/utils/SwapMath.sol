// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract SwapMath {
    function sellSlippage(uint256 expected, uint256 actual, uint256 maxBps) public pure returns (uint256) {
        if (actual >= expected) return 0;
        return (expected - actual) * maxBps / expected;
    }

    function buySlippage(uint256 expected, uint256 actual, uint256 maxBps) public pure returns (uint256) {
        if (actual <= expected) return 0;
        return (actual - expected) * maxBps / expected;
    }
}
