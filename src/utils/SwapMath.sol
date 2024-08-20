// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library SwapMath {
    function slippage(uint256 expected, uint256 actual) public pure returns (uint256 /* million bps */ ) {
        if (actual >= expected) return 0;
        return (expected - actual) * 100_000_000 / expected;
    }
}
