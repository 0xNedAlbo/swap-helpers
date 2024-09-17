// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SwapType, ISwapHelper } from "./interfaces/ISwapHelper.sol";

import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { Test } from "forge-std/src/Test.sol";

contract UniswapV3Helper is ISwapHelper, Test {
    using SafeERC20 for IERC20;

    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV3Pool[] public pools;

    address public token0;
    address public token1;

    bytes path;
    bytes reversePath;

    modifier onlyPools() {
        bool isPool = false;
        for (uint256 i = 0; (i < pools.length) && (isPool == false); i++) {
            if (msg.sender == address(pools[i])) isPool = true;
        }
        require(isPool, "caller not a pool");
        _;
    }

    function initialize(address pool) public {
        require(pools.length == 0, "already initialized");
        pools.push(IUniswapV3Pool(pool));
        setupPath();
        setupReversePath();
    }

    function initialize(address pool1, address pool2) public {
        require(pools.length == 0, "already initialized");
        pools.push(IUniswapV3Pool(pool1));
        pools.push(IUniswapV3Pool(pool2));
        setupPath();
        setupReversePath();
    }

    function initialize(address pool1, address pool2, address pool3) public {
        require(pools.length == 0, "already initialized");
        pools.push(IUniswapV3Pool(pool1));
        pools.push(IUniswapV3Pool(pool2));
        pools.push(IUniswapV3Pool(pool3));
        setupPath();
        setupReversePath();
    }

    function setupPath() private {
        require(pools.length > 0, "no pools");
        bytes memory path_;
        if (pools.length == 1) {
            token0 = pools[0].token0();
            token1 = pools[0].token1();
            path_ = abi.encodePacked(token0, pools[0].fee(), token1);
        } else {
            if (pools[0].token1() == pools[1].token0() || pools[0].token1() == pools[1].token1()) {
                token0 = pools[0].token0();
                token1 = pools[0].token1();
            } else if (pools[0].token0() == pools[1].token0() || pools[0].token0() == pools[1].token1()) {
                token0 = pools[0].token1();
                token1 = pools[0].token0();
            } else {
                revert("pool tokens mismatch");
            }
            path_ = abi.encodePacked(token0, pools[0].fee(), token1);

            for (uint256 i = 1; i < pools.length; i++) {
                if (token1 == pools[i].token0()) {
                    token1 = pools[i].token1();
                } else if (token1 == pools[i].token1()) {
                    token1 = pools[i].token0();
                } else {
                    revert("pool tokens mismatch");
                }
                path_ = bytes.concat(path_, abi.encodePacked(pools[i].fee(), token1));
            }
        }
        path = path_;
    }

    function setupPools(bytes memory path_) private {
        // Each segment is 23 bytes: 20 bytes for token and 3 bytes for fee
        uint256 numPools = (path_.length - 20) / 23; // -20 for the last token that has no fee

        token0 = toAddress(path_, 0);

        uint256 offset = 0;
        for (uint256 i = 0; i < numPools; i++) {
            // Extract token address (20 bytes)
            address poolToken0 = toAddress(path_, offset);
            offset += 20;

            // Extract fee (3 bytes)
            uint24 poolFees = toUint24(path_, offset);
            offset += 3;

            // Extract the next token
            address poolToken1 = toAddress(path_, offset);

            // Find pool address
            address pool = factory.getPool(poolToken0, poolToken1, poolFees);
            pools.push(IUniswapV3Pool(pool));
        }

        // Extract the last token (it has no fee)
        token1 = toAddress(path_, offset);
    }

    function setupReversePath() private {
        uint256 numPools = (path.length - 20) / 23; // -20 for the last token that has no fee

        token0 = toAddress(path, 0);

        uint256 offset = path.length - 20;
        bytes memory reversePath_ = abi.encodePacked(toAddress(path, offset));
        for (uint256 i = 0; i < numPools; i++) {
            offset -= 3;
            uint24 fees = toUint24(path, offset);
            offset -= 20;
            address addr = toAddress(path, offset);
            bytes memory encoded = abi.encodePacked(fees, addr);
            reversePath_ = bytes.concat(reversePath_, encoded);
        }
        reversePath = reversePath_;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function previewBuyToken0(uint256 amount0) external override returns (uint256 amount1) {
        require(amount0 <= uint256(type(int256).max), "!<=int256.max");
        address token = token0;
        amount1 = amount0;

        for (uint256 i = 0; i < pools.length; i++) {
            IUniswapV3Pool pool = pools[i];
            (token, amount1) = previewBuyToken(pool, token, amount1);
        }
    }

    function previewBuyToken1(uint256 amount1) external override returns (uint256 amount0) {
        require(amount1 <= uint256(type(int256).max), "!<=int256.max");
        address token = token1;
        uint256 amount = amount1;
        uint256 i = pools.length;
        do {
            i--;
            IUniswapV3Pool pool = pools[i];
            (token, amount) = previewBuyToken(pool, token, amount);
        } while (i > 0);
        amount0 = amount;
    }

    function previewBuyToken(
        IUniswapV3Pool pool,
        address token,
        uint256 amountIn
    )
        private
        returns (address tokenOut, uint256 amountOut)
    {
        bool zeroForOne = token == pool.token0() ? false : true;
        bytes memory callbackData = abi.encode(zeroForOne ? SwapType.PreviewBuyToken1 : SwapType.PreviewBuyToken0);
        uint160 sqrtPriceLimitX96 = zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1;
        amountOut = amountIn;
        try pool.swap(address(this), zeroForOne, -int256(amountOut), sqrtPriceLimitX96, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amountOut = abi.decode(bytes(revertData), (uint256));
            token = token == pool.token0() ? pool.token1() : pool.token0();
        }
        tokenOut = zeroForOne ? pool.token0() : pool.token1();
    }

    function previewSellToken0(uint256 amount0) external override returns (uint256 amount1) {
        require(amount0 <= uint256(type(int256).max), "!<=int256.max");
        address token = token0;
        amount1 = amount0;

        for (uint256 i = 0; i < pools.length; i++) {
            IUniswapV3Pool pool = pools[i];
            (token, amount1) = previewSellToken(pool, token, amount1);
        }
    }

    function previewSellToken1(uint256 amount1) external override returns (uint256 amount0) {
        require(amount1 <= uint256(type(int256).max), "!<=int256.max");
        address token = token1;
        amount0 = amount1;
        uint256 i = pools.length;
        do {
            i--;
            IUniswapV3Pool pool = pools[i];
            (token, amount0) = previewSellToken(pool, token, amount0);
        } while (i > 0);
    }

    function previewSellToken(
        IUniswapV3Pool pool,
        address token,
        uint256 amountOut
    )
        private
        returns (address tokenIn, uint256 amountIn)
    {
        bool zeroForOne = token == pool.token0() ? true : false;
        bytes memory callbackData = abi.encode(zeroForOne ? SwapType.PreviewSellToken0 : SwapType.PreviewSellToken1);
        uint160 sqrtPriceLimitX96 = zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1;
        try pool.swap(address(this), zeroForOne, int256(amountOut), sqrtPriceLimitX96, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amountIn = abi.decode(bytes(revertData), (uint256));
            token = token == pool.token0() ? pool.token1() : pool.token0();
        }
        tokenIn = zeroForOne ? pool.token1() : pool.token0();
    }

    function buyToken0(
        uint256 amount0,
        uint256 maxAmount1,
        address receiver
    )
        external
        override
        returns (uint256 amount1)
    {
        IERC20(token1).safeTransferFrom(msg.sender, address(this), maxAmount1);
        IERC20(token1).approve(address(router), maxAmount1);
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: path,
            recipient: receiver,
            deadline: block.timestamp,
            amountOut: amount0,
            amountInMaximum: maxAmount1
        });
        amount1 = router.exactOutput(params);
        if (amount1 < maxAmount1) {
            IERC20(token1).safeTransfer(msg.sender, maxAmount1 - amount1);
        }
    }

    function buyToken1(
        uint256 amount1,
        uint256 maxAmount0,
        address receiver
    )
        external
        override
        returns (uint256 amount0)
    {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), maxAmount0);
        IERC20(token0).approve(address(router), maxAmount0);
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: reversePath,
            recipient: receiver,
            deadline: block.timestamp,
            amountOut: amount1,
            amountInMaximum: maxAmount0
        });
        amount0 = router.exactOutput(params);
        if (amount0 < maxAmount0) {
            IERC20(token0).safeTransfer(msg.sender, maxAmount0 - amount0);
        }
    }

    function sellToken0(
        uint256 amount0,
        uint256 minAmount1,
        address receiver
    )
        external
        override
        returns (uint256 amount1)
    {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token0).approve(address(router), amount0);
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: receiver,
            deadline: block.timestamp,
            amountIn: amount0,
            amountOutMinimum: minAmount1
        });
        amount1 = router.exactInput(params);
    }

    function sellToken1(
        uint256 amount1,
        uint256 minAmount0,
        address receiver
    )
        external
        override
        returns (uint256 amount0)
    {
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        IERC20(token1).approve(address(router), amount1);
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: reversePath,
            recipient: receiver,
            deadline: block.timestamp,
            amountIn: amount1,
            amountOutMinimum: minAmount0
        });
        amount0 = router.exactInput(params);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    )
        external
        view
        onlyPools
    {
        (SwapType swapType) = abi.decode(data, (SwapType));
        if (swapType == SwapType.PreviewBuyToken1) {
            revert(string(abi.encode(uint256(amount0Delta))));
        } else if (swapType == SwapType.PreviewBuyToken0) {
            revert(string(abi.encode(uint256(amount1Delta))));
        } else if (swapType == SwapType.PreviewSellToken1) {
            revert(string(abi.encode(uint256(-amount0Delta))));
        } else if (swapType == SwapType.PreviewSellToken0) {
            revert(string(abi.encode(uint256(-amount1Delta))));
        }
        /*
        else if (swapType == SwapType.BuyToken0) {
            IERC20(token1).safeTransferFrom(swapCaller, msg.sender, uint256(amount1Delta));
        } else if (swapType == SwapType.BuyToken1) {
            IERC20(token0).safeTransferFrom(swapCaller, msg.sender, uint256(amount0Delta));
        } else if (swapType == SwapType.SellToken0) {
            IERC20(token0).safeTransferFrom(swapCaller, msg.sender, uint256(amount0Delta));
        } else if (swapType == SwapType.SellToken1) {
            IERC20(token1).safeTransferFrom(swapCaller, msg.sender, uint256(amount1Delta));
        }*/
    }
}
