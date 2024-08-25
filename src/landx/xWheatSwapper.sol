// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.18;
pragma abicoder v2;

import { console } from "forge-std/src/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniV3Swapper } from "../interfaces/IUniV3Swapper.sol";

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SwapMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract xWheatSwapper is IUniV3Swapper {
    address public immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable XWHEAT = 0x189cA29981b6ad3ab01c2959B90eAfcA637076a8;

    address public immutable tokenA = USDC;
    address public immutable tokenB = XWHEAT;

    // token0 = xWHEAT, token1 = USDC
    IUniswapV3Pool public xWheatPool = IUniswapV3Pool(0x8C00238B17397a194c4dd5A623b1FcdfF684f1D6);

    enum SwapType {
        PreviewSwapSellTokenA,
        PreviewSwapSellTokenB,
        PreviewSwapBuyTokenA,
        PreviewSwapBuyTokenB
    }

    function previewBuyUsdc(uint256 usdcAmount) external returns (uint256 xWheatAmount) {
        return previewBuyA(usdcAmount);
    }

    function previewBuyXWheat(uint256 xWheatAmount) external returns (uint256 usdcAmount) {
        return previewBuyB(xWheatAmount);
    }

    function previewSellUsdc(uint256 usdcAmount) external returns (uint256 xWheatAmount) {
        return previewSellA(usdcAmount);
    }

    function previewSellXWheat(uint256 xWheatAmount) external returns (uint256 usdcAmount) {
        return previewBuyB(xWheatAmount);
    }

    function previewBuyA(uint256 amountA) public override returns (uint256 amountOut) {
        require(amountA <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewSwapBuyTokenA);
        try xWheatPool.swap(address(this), true, -int256(amountA), TickMath.MIN_SQRT_RATIO + 1, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amountOut = abi.decode(bytes(revertData), (uint256));
        }
        return amountOut;
    }

    function previewBuyB(uint256 amountB) public override returns (uint256 amountOut) {
        require(amountB <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewSwapBuyTokenB);
        try xWheatPool.swap(address(this), false, -int256(amountB), TickMath.MAX_SQRT_RATIO - 1, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amountOut = abi.decode(bytes(revertData), (uint256));
        }
        return amountOut;
    }

    function previewSellA(uint256 amountA) public override returns (uint256 amountOut) {
        require(amountA <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewSwapSellTokenA);
        try xWheatPool.swap(
            address(this), // recipient with callback
            false, // zeroToOne
            int256(amountA), // swap amount
            TickMath.MAX_SQRT_RATIO - 1, // sqrtPriceLimitX96
            callbackData
        ) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amountOut = abi.decode(bytes(revertData), (uint256));
        }
        return amountOut;
    }

    function previewSellB(uint256 amountB) public override returns (uint256 amountOut) {
        require(amountB <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewSwapSellTokenB);
        try xWheatPool.swap(address(this), true, int256(amountB), TickMath.MIN_SQRT_RATIO + 1, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amountOut = abi.decode(bytes(revertData), (uint256));
        }
        return amountOut;
    }

    function sellA(uint256 amountA, uint256 minAmountB, address receiver) external override returns (uint256) {
        revert("not implemented");
    }

    function sellB(uint256 amountB, uint256 minAmountA, address receiver) external override returns (uint256) {
        revert("not implemented");
    }

    function buyA(uint256 amountA, uint256 maxAmountB, address receiver) external override returns (uint256) {
        revert("not implemented");
    }

    function buyB(uint256 amountB, uint256 maxAmountA, address receiver) external override returns (uint256) {
        revert("not implemented");
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        (SwapType swapType) = abi.decode(data, (SwapType));
        if (swapType == SwapType.PreviewSwapBuyTokenA) {
            revert(string(abi.encode(uint256(amount0Delta))));
        }
        if (swapType == SwapType.PreviewSwapBuyTokenB) {
            revert(string(abi.encode(uint256(amount1Delta))));
        }
        if (swapType == SwapType.PreviewSwapSellTokenA) {
            revert(string(abi.encode(uint256(-amount0Delta))));
        }
        if (swapType == SwapType.PreviewSwapSellTokenB) {
            revert(string(abi.encode(uint256(-amount1Delta))));
        }
        revert("SwapType not implemented");
    }
}
