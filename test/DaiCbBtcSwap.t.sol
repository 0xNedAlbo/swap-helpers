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
import { UniswapV3Helper } from "@src/UniswapV3Helper.sol";
import { SwapHelperTest } from "./utils/SwapHelperTest.sol";

contract DaiCbBtcSwapTest is SwapHelperTest {
    using Math for uint256;
    using Slippage for uint256;

    address constant DAI_USDC_POOL = 0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168;
    address constant USDC_CBBTC_POOL = 0x4548280AC92507C9092a511C7396Cbea78FA9E49;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    IAggregator daiAggregator = IAggregator(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    IAggregator btcAggregator = IAggregator(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);

    constructor() SwapHelperTest() { }

    function setUp_swapHelper() public override returns (address) {
        token0 = DAI;
        token1 = CBBTC;
        UniswapV3Helper swapHelper = new UniswapV3Helper(router);
        swapHelper.initialize(DAI_USDC_POOL, USDC_CBBTC_POOL);
        return address(swapHelper);
    }

    function setUp_fuzzer()
        public
        virtual
        override
        returns (uint256 token0FuzzMin, uint256 token0FuzzMax, uint256 token1FuzzMin, uint256 token1FuzzMax)
    {
        uint256 daiMin = 1e18;
        uint256 daiMax = 100_000e18;
        uint256 cbbtcMin = 1e6;
        uint256 cbbtcMax = 4e8;
        token0FuzzMin = token0 == DAI ? daiMin : cbbtcMin;
        token0FuzzMax = token0 == DAI ? daiMax : cbbtcMax;
        token1FuzzMin = token1 == DAI ? daiMin : cbbtcMin;
        token1FuzzMax = token1 == DAI ? daiMax : cbbtcMax;
    }

    function setUp_maxDeviation() public virtual override returns (int24) {
        return 500;
    }

    function test_00_poolComposition() public view {
        require(token0 == DAI || token1 == DAI, "pool has no DAI");
        require(token0 == CBBTC || token1 == address(CBBTC), "pool has no CBBTC");
        require(token0 != token1, "pool with identical tokens");
    }

    function token0AmountToUsd(uint256 token0Amount) public virtual override returns (uint256 usdAmount) {
        IAggregator priceFeed = token0 == DAI ? daiAggregator : btcAggregator;
        (, int256 latestAnswer,,,) = priceFeed.latestRoundData();
        uint8 token0Decimals = IERC20Metadata(token0).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        usdAmount = token0Amount.mulDiv(uint256(latestAnswer), 10 ** priceFeedDecimals);
        usdAmount = usdAmount.mulDiv(1e18, 10 ** token0Decimals);
    }

    function token1AmountToUsd(uint256 token1Amount) public virtual override returns (uint256 usdAmount) {
        IAggregator priceFeed = token1 == DAI ? daiAggregator : btcAggregator;
        (, int256 latestAnswer,,,) = priceFeed.latestRoundData();
        uint8 token1Decimals = IERC20Metadata(token1).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        usdAmount = token1Amount.mulDiv(uint256(latestAnswer), 10 ** priceFeedDecimals);
        usdAmount = usdAmount.mulDiv(1e18, 10 ** token1Decimals);
    }

    function usdAmountToToken0(uint256 usdAmount) public virtual override returns (uint256 token0Amount) {
        IAggregator priceFeed = token0 == DAI ? daiAggregator : btcAggregator;
        (, int256 latestAnswer,,,) = priceFeed.latestRoundData();
        uint8 token0Decimals = IERC20Metadata(token0).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        token0Amount = usdAmount.mulDiv(10 ** priceFeedDecimals, uint256(latestAnswer));
        token0Amount = token0Amount.mulDiv(10 ** token0Decimals, 1e18);
    }

    function usdAmountToToken1(uint256 usdAmount) public virtual override returns (uint256 token1Amount) {
        IAggregator priceFeed = token1 == DAI ? daiAggregator : btcAggregator;
        (, int256 latestAnswer,,,) = priceFeed.latestRoundData();
        uint8 token1Decimals = IERC20Metadata(token1).decimals();
        uint8 priceFeedDecimals = priceFeed.decimals();
        token1Amount = usdAmount.mulDiv(10 ** priceFeedDecimals, uint256(latestAnswer));
        token1Amount = token1Amount.mulDiv(10 ** token1Decimals, 1e18);
    }
}
