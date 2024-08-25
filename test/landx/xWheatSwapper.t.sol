// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { Test } from "forge-std/src/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { xWheatSwapper } from "@src/landx/xWheatSwapper.sol";

contract xWheatSwapperTest is Test {
    xWheatSwapper public swap;

    IERC20 USDC;
    IERC20 xWheat;

    address user;

    function setUp() public {
        swap = new xWheatSwapper();
        USDC = IERC20(swap.USDC());
        xWheat = IERC20(swap.XWHEAT());
    }

    function setUp_user() public {
        user = vm.addr(1);
    }

    function test_previewSellA() public {
        uint256 amountOut = swap.previewBuyA(5000 ether);
        log_uint(amountOut);
    }
}
