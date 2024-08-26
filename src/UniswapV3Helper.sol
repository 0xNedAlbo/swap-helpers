// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.18;
pragma abicoder v2;

import { console } from "forge-std/src/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SwapType, ISwapHelper } from "./interfaces/ISwapHelper.sol";

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/SwapMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

abstract contract UniswapV3Helper is ISwapHelper {
    using SafeERC20 for IERC20;

    IUniswapV3Pool public pool;

    constructor(address poolAddress) {
        pool = IUniswapV3Pool(poolAddress);
    }

    function token0() public view returns (address) {
        return pool.token0();
    }

    function token1() public view returns (address) {
        return pool.token1();
    }

    function previewBuyToken0(uint256 amount0) public virtual returns (uint256 amount1) {
        require(amount0 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewBuyToken0, msg.sender);
        try pool.swap(address(this), false, -int256(amount0), TickMath.MAX_SQRT_RATIO - 1, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amount1 = abi.decode(bytes(revertData), (uint256));
        }
        return amount1;
    }

    function previewBuyToken1(uint256 amount1) public virtual returns (uint256 amount0) {
        require(amount1 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewBuyToken1, msg.sender);
        try pool.swap(address(this), true, -int256(amount1), TickMath.MIN_SQRT_RATIO + 1, callbackData) {
            revert("!notReverted");
        } catch Error(string memory revertData) {
            amount1 = abi.decode(bytes(revertData), (uint256));
        }
        return amount1;
    }

    function previewSellToken0(uint256 amount0) public virtual returns (uint256 amountOut) {
        require(amount0 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewSellToken0, msg.sender);
        try pool.swap(address(this), true, int256(amount0), TickMath.MIN_SQRT_RATIO + 1, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amountOut = abi.decode(bytes(revertData), (uint256));
        }
        return amountOut;
    }

    function previewSellToken1(uint256 amount1) public virtual returns (uint256 amount0) {
        require(amount1 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewSellToken1, msg.sender);
        try pool.swap(address(this), false, int256(amount1), TickMath.MAX_SQRT_RATIO - 1, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amount0 = abi.decode(bytes(revertData), (uint256));
        }
        return amount0;
    }

    function buyToken0(uint256 amount0, uint256 maxAmountIn, address receiver) public returns (uint256 amountIn) {
        require(amount0 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.BuyToken0, msg.sender);
        (, int256 amount1) =
            pool.swap(address(this), false, -int256(amount0), TickMath.MAX_SQRT_RATIO - 1, callbackData);
        amountIn = uint256(amount1);
        IERC20(pool.token0()).safeTransfer(receiver, amount0);
        emit SwapFromToken1(msg.sender, receiver, uint256(amountIn), amount0);
        require(amountIn <= maxAmountIn, "!slippage");
    }

    function buyToken1(uint256 amount1, uint256 maxAmountIn, address receiver) public returns (uint256 amountIn) {
        require(amount1 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.BuyToken1, msg.sender);
        (int256 amount0,) = pool.swap(address(this), true, -int256(amount1), TickMath.MIN_SQRT_RATIO + 1, callbackData);
        amountIn = uint256(amount0);
        IERC20(pool.token1()).safeTransfer(receiver, amount1);
        emit SwapFromToken0(msg.sender, receiver, uint256(amountIn), amount1);
        require(amountIn <= maxAmountIn, "!slippage");
    }

    function sellToken0(
        uint256 amount0,
        uint256 minAmountOut,
        address receiver
    )
        public
        virtual
        returns (uint256 amountOut)
    {
        require(amount0 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.SellToken0, msg.sender);
        (, int256 amount1) = pool.swap(address(this), true, int256(amount0), TickMath.MIN_SQRT_RATIO + 1, callbackData);
        amountOut = uint256(-amount1);
        IERC20(pool.token1()).safeTransfer(receiver, amountOut);
        emit SwapFromToken0(msg.sender, receiver, amount0, amountOut);
        require(amountOut >= minAmountOut, "!slippage");
    }

    function sellToken1(
        uint256 amount1,
        uint256 minAmountOut,
        address receiver
    )
        public
        virtual
        returns (uint256 amountOut)
    {
        require(amount1 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.SellToken1, msg.sender);
        (int256 amount0,) = pool.swap(address(this), false, int256(amount1), TickMath.MAX_SQRT_RATIO - 1, callbackData);
        amountOut = uint256(-amount0);
        IERC20(pool.token0()).safeTransfer(receiver, amountOut);
        emit SwapFromToken0(msg.sender, receiver, amount1, amountOut);
        require(amountOut >= minAmountOut, "!slippage");
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        (SwapType swapType, address swapCaller) = abi.decode(data, (SwapType, address));
        if (swapType == SwapType.PreviewBuyToken1) {
            revert(string(abi.encode(uint256(amount0Delta))));
        } else if (swapType == SwapType.PreviewBuyToken0) {
            revert(string(abi.encode(uint256(amount1Delta))));
        } else if (swapType == SwapType.PreviewSellToken1) {
            revert(string(abi.encode(uint256(-amount0Delta))));
        } else if (swapType == SwapType.PreviewSellToken0) {
            revert(string(abi.encode(uint256(-amount1Delta))));
        } else if (swapType == SwapType.BuyToken0) {
            console.log("swapCaller: ", swapCaller);
            console.log("msg.sender: ", msg.sender);
            console.log("amount1Delta: ", amount1Delta);
            IERC20(pool.token1()).safeTransferFrom(swapCaller, msg.sender, uint256(amount1Delta));
        } else if (swapType == SwapType.BuyToken1) {
            console.log("swapCaller: ", swapCaller);
            console.log("msg.sender: ", msg.sender);
            console.log("amount0Delta: ", amount0Delta);
            IERC20(pool.token0()).safeTransferFrom(swapCaller, msg.sender, uint256(amount0Delta));
        } else if (swapType == SwapType.SellToken0) {
            console.log("swapCaller: ", swapCaller);
            console.log("msg.sender: ", msg.sender);
            console.log("amount0Delta: ", amount0Delta);
            IERC20(pool.token0()).safeTransferFrom(swapCaller, msg.sender, uint256(amount0Delta));
        } else if (swapType == SwapType.SellToken1) {
            console.log("swapCaller: ", swapCaller);
            console.log("msg.sender: ", msg.sender);
            console.log("amount1Delta: ", amount1Delta);
            IERC20(pool.token1()).safeTransferFrom(swapCaller, msg.sender, uint256(amount1Delta));
        }
    }
}
