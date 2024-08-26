// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library Slippage {
    using Math for uint256;

    int24 constant MAX_BPS = 10_000;
    int24 constant MIN_BPS = -10_000;

    uint256 constant MAX_BPS_UINT = 10_000;

    function slippage(uint256 expected, uint256 actual) public pure returns (int24) {
        require(expected > 0, "!expected cannot be zero");
        uint256 bps;
        if (actual >= expected) {
            bps = (actual - expected).mulDiv(MAX_BPS_UINT, expected);
            if (bps >= uint24(type(int24).max)) return type(int24).max;
            return int24((uint24(bps)));
        }
        bps = (expected - actual).mulDiv(MAX_BPS_UINT, expected);
        return -int24(uint24(bps));
    }

    function applySlippage(uint256 amount, int24 slippageBps) public pure returns (uint256) {
        require(slippageBps >= MIN_BPS, "!invalid minimum bps");
        require(slippageBps <= type(int24).max - MAX_BPS, "!invalid maximum bps");
        return amount.mulDiv(uint256(uint24(MAX_BPS + slippageBps)), uint256(uint24(MAX_BPS)));
    }
}
