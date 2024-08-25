// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { console } from "forge-std/src/console.sol";
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
        uint256 amountOut = swap.previewSellA(5000 * (10 ** 6));
        console.log("Sold 5000 USDC for xWHEAT: ", amountOut);
    }

    function test_previewSellB() public {
        uint256 amountOut = swap.previewSellB(1000 * (10 ** 6));
        console.log("Sold 1000 xWHEAT for USDC: ", amountOut);
    }

    function test_previewBuyA() public {
        uint256 amountOut = swap.previewBuyA(5000 * (10 ** 6));
        console.log("Bought 5000 USDC for xWHEAT: ", amountOut);
    }

    function test_previewBuyB() public {
        uint256 amountOut = swap.previewBuyB(1000 * (10 ** 6));
        console.log("Sold 1000 xWHEAT for USDC: ", amountOut);
    }
}
