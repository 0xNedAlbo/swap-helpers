// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SwapType, ISwapHelper } from "./interfaces/ISwapHelper.sol";

import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { console } from "forge-std/src/console.sol";

contract RoutedSwapHelper is ISwapHelper {
    using SafeERC20 for IERC20;

    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

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

    constructor(bytes memory path_) {
        require(path_.length >= 43, "path too short");
        path = path_;
        setupPools(path_);
        setupReversePath(path_);
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

    function setupReversePath(bytes memory path_) private {
        uint256 numPools = (path_.length - 20) / 23; // -20 for the last token that has no fee

        token0 = toAddress(path_, 0);

        uint256 offset = path_.length - 20;
        bytes memory reversePath_ = abi.encodePacked(toAddress(path_, offset));
        for (uint256 i = 0; i < numPools; i++) {
            offset -= 3;
            uint24 fees = toUint24(path_, offset);
            offset -= 20;
            address addr = toAddress(path_, offset);
            bytes memory encoded = abi.encodePacked(fees, addr);
            reversePath_ = bytes.concat(reversePath_, encoded);
        }
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

    function previewSellToken0(uint256 amount0) external override returns (uint256 previewAmount) { }

    function previewSellToken1(uint256 amount1) external override returns (uint256 previewAmount) { }

    function previewBuyToken0(uint256 amount0) external override returns (uint256 previewAmount) { }

    function previewBuyToken1(uint256 amount1) external override returns (uint256 previewAmount) { }

    function buyToken0(
        uint256 amount0,
        uint256 maxAmount1,
        address receiver
    )
        external
        override
        returns (uint256 amount1)
    {
        /* require(amount0 <= uint256(type(int256).max), "!<=int256.max");
        bytes memory callbackData = abi.encode(SwapType.PreviewBuyToken0, msg.sender);
        try pool.swap(address(this), false, -int256(amount0), TickMath.MAX_SQRT_RATIO - 1, callbackData) {
            revert("!reverted");
        } catch Error(string memory revertData) {
            amount1 = abi.decode(bytes(revertData), (uint256));
        }
        return amount1;*/
    }

    function buyToken1(uint256 amount1, uint256 maxAmount0, address receiver) external override returns (uint256) { }

    function sellToken0(
        uint256 amount0,
        uint256 minAmount1,
        address receiver
    )
        external
        override
        returns (uint256 amountReceived)
    { }

    function sellToken1(
        uint256 amount1,
        uint256 minAmount0,
        address receiver
    )
        external
        override
        returns (uint256 amountReceived)
    { }
}
