// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { StdCheats, Test } from "forge-std/src/test.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IWETH } from "mock-tokens/src/interfaces/IWETH.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IAggregator } from "@src/interfaces/chainlink/IAggregator.sol";

import { ISwapHelper } from "@src/interfaces/ISwapHelper.sol";
import { Slippage } from "@src/utils/Slippage.sol";
import { UniswapV3Helper } from "@src/UniswapV3Helper.sol";
import { UniswapV3HelperTest } from "./utils/UniswapV3HelperTest.sol";

contract DaiEthSwapTest is UniswapV3HelperTest {
    using Math for uint256;
    using Slippage for uint256;

    address constant POOL_ADDRESS = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IAggregator daiAggregator = IAggregator(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    IAggregator ethAggregator = IAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    constructor() UniswapV3HelperTest() { }

    function setUp_swapHelper() public override returns (address) {
        return address(new UniswapV3Helper(POOL_ADDRESS));
    }

    function setUp_fuzzer()
        public
        virtual
        override
        returns (uint256 token0FuzzMin, uint256 token0FuzzMax, uint256 token1FuzzMin, uint256 token1FuzzMax)
    {
        uint256 daiMin = 1e18;
        uint256 daiMax = 100_000e18;
        uint256 wethMin = 1e16;
        uint256 wethMax = 100e18;
        token0FuzzMin = token0 == DAI ? daiMin : wethMin;
        token0FuzzMax = token0 == DAI ? daiMax : wethMax;
        token1FuzzMin = token1 == DAI ? daiMin : wethMin;
        token1FuzzMax = token1 == DAI ? daiMax : wethMax;
    }

    function setUp_maxDeviation() public virtual override returns (int24) {
        return 1000;
    }

    function test_00_poolComposition() public view {
        require(token0 == DAI || token1 == DAI, "pool has no DAI");
        require(token0 == address(WETH) || token1 == address(WETH), "pool has no WETH");
        require(token0 != token1, "pool with identical tokens");
    }

    function token0AmountToUsd(uint256 token0Amount) public virtual override returns (uint256 usdAmount) {
        IAggregator priceFeed = token0 == DAI ? daiAggregator : ethAggregator;
        uint256 latestAnswer = uint256(priceFeed.latestAnswer());
        uint8 token0Decimals = IERC20Metadata(token0).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        usdAmount = token0Amount.mulDiv(latestAnswer, 10 ** priceFeedDecimals);
        usdAmount = usdAmount.mulDiv(1e18, 10 ** token0Decimals);
    }

    function token1AmountToUsd(uint256 token1Amount) public virtual override returns (uint256 usdAmount) {
        IAggregator priceFeed = token1 == DAI ? daiAggregator : ethAggregator;
        uint256 latestAnswer = uint256(priceFeed.latestAnswer());
        uint8 token1Decimals = IERC20Metadata(token1).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        usdAmount = token1Amount.mulDiv(latestAnswer, 10 ** priceFeedDecimals);
        usdAmount = usdAmount.mulDiv(1e18, 10 ** token1Decimals);
    }

    function usdAmountToToken0(uint256 usdAmount) public virtual override returns (uint256 token0Amount) {
        IAggregator priceFeed = token0 == DAI ? daiAggregator : ethAggregator;
        uint256 latestAnswer = uint256(priceFeed.latestAnswer());
        uint8 token0Decimals = IERC20Metadata(token0).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        token0Amount = usdAmount.mulDiv(10 ** priceFeedDecimals, latestAnswer);
        token0Amount = token0Amount.mulDiv(10 ** token0Decimals, 1e18);
    }

    function usdAmountToToken1(uint256 usdAmount) public virtual override returns (uint256 token1Amount) {
        IAggregator priceFeed = token1 == DAI ? daiAggregator : ethAggregator;
        uint256 latestAnswer = uint256(priceFeed.latestAnswer());
        uint8 token1Decimals = IERC20Metadata(token1).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        token1Amount = usdAmount.mulDiv(10 ** priceFeedDecimals, latestAnswer);
        token1Amount = token1Amount.mulDiv(10 ** token1Decimals, 1e18);
    }
}
