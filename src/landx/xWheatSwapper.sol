// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.18;
pragma abicoder v2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwapper } from "../interfaces/ISwapper.sol";

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SwapMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract xWheatSwapper is ISwapper {
    address public immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable XWHEAT = 0x189cA29981b6ad3ab01c2959B90eAfcA637076a8;

    address public immutable tokenA = USDC;
    address public immutable tokenB = XWHEAT;

    IUniswapV3Pool public xWheatPool = IUniswapV3Pool(0x8C00238B17397a194c4dd5A623b1FcdfF684f1D6);

    function previewSellA(uint256 amountA) external view override returns (uint256 amountOut) {
        require(amountA <= uint256(type(int256).max), "!>int256.max");
        (uint160 sqrtPriceX96, int24 tick,,,,,) = xWheatPool.slot0();
        uint128 liquidity = xWheatPool.liquidity();
        uint24 fee = xWheatPool.fee();
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        (amountOut,,,) = SwapMath.computeSwapStep(sqrtPriceX96, sqrtPriceLimitX96, liquidity, int256(amountA), fee);
        return amountOut;
    }

    function previewSellB(uint256 amountB) external view override returns (uint256) {
        return 0;
    }

    function previewBuyA(uint256 amountA) external view override returns (uint256) {
        return 0;
    }

    function previewBuyB(uint256 amountB) external view override returns (uint256) {
        return 0;
    }

    function sellA(uint256 amountA, uint256 minAmountB, address receiver) external override returns (uint256) {
        return 0;
    }

    function sellB(uint256 amountB, uint256 minAmountA, address receiver) external override returns (uint256) {
        return 0;
    }

    function buyA(uint256 amountA, uint256 maxAmountB, address receiver) external override returns (uint256) {
        return 0;
    }

    function buyB(uint256 amountB, uint256 maxAmountA, address receiver) external override returns (uint256) {
        return 0;
    }
}
