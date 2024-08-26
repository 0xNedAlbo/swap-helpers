// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { console } from "forge-std/src/console.sol";
import { StdCheats, Test } from "forge-std/src/test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "mock-tokens/src/interfaces/IWETH.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IAggregator } from "@src/interfaces/chainlink/IAggregator.sol";

import { ISwapHelper } from "@src/interfaces/ISwapHelper.sol";
import { Slippage } from "@src/utils/Slippage.sol";
import { DaiToEthSwapHelper } from "@src/DaiToEthSwapHelper.sol";
import { UniswapV3HelperTest } from "./utils/UniswapV3HelperTest.sol";

contract DaiToEthSwapHelperTest is UniswapV3HelperTest {
    using Math for uint256;
    using Slippage for uint256;

    address constant POOL_ADDRESS = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IAggregator chainlink = IAggregator(0x773616E4d11A78F511299002da57A0a94577F1f4);

    int24 public maxDeviation = 1200;

    DaiToEthSwapHelper public helper;

    constructor() UniswapV3HelperTest() { }

    function setUp_swapHelper() public override returns (address) {
        helper = new DaiToEthSwapHelper();
        return address(helper);
    }

    function setUp_fuzzer()
        public
        virtual
        override
        returns (uint256 token0FuzzMin, uint256 token0FuzzMax, uint256 token1FuzzMin, uint256 token1FuzzMax)
    {
        token0FuzzMin = 10 ether;
        token0FuzzMax = 100_000 ether;
        token1FuzzMin = 0.1 ether;
        token1FuzzMax = 100 ether;
    }

    function test_buyMaxDaiAmount() public {
        if (pool.token0() == DAI) t_buyMaxToken0Amount(maxDeviation);
        else t_buyMaxToken1Amount(maxDeviation);
    }

    function test_buyMinDaiAmount() public {
        if (pool.token0() == DAI) t_buyMinToken0Amount(maxDeviation);
        else t_buyMinToken1Amount(maxDeviation);
    }

    function test_buyMaxWethAmount() public {
        if (pool.token0() == address(WETH)) t_buyMaxToken0Amount(maxDeviation);
        else t_buyMaxToken1Amount(maxDeviation);
    }

    function test_buyMinWethAmount() public {
        if (pool.token0() == address(WETH)) t_buyMinToken0Amount(maxDeviation);
        else t_buyMinToken1Amount(maxDeviation);
    }

    function test_previewMaxBuyWeth(uint256 wethAmount) public {
        if (pool.token0() == address(WETH)) t_previewBuyToken0(wethAmount, maxDeviation);
        else t_previewBuyToken1(wethAmount, maxDeviation);
    }

    function test_previewSellDai(uint256 daiAmount) public {
        if (pool.token0() == DAI) t_previewSellToken0(daiAmount, maxDeviation);
        else t_previewSellToken1(daiAmount, maxDeviation);
    }

    function test_previewSellWeth(uint256 wethAmount) public {
        if (pool.token0() == address(WETH)) t_previewSellToken0(wethAmount, maxDeviation);
        else t_previewSellToken1(wethAmount, maxDeviation);
    }

    function test_sellMaxDaiAmount() public {
        if (pool.token0() == DAI) t_sellMinToken0Amount(maxDeviation);
        else t_sellMinToken1Amount(maxDeviation);
    }

    function test_sellMinDaiAmount() public {
        if (pool.token0() == DAI) t_sellMinToken0Amount(maxDeviation);
        else t_sellMinToken1Amount(maxDeviation);
    }

    function test_sellMaxWethAmount() public {
        if (pool.token0() == address(WETH)) t_sellMinToken0Amount(maxDeviation);
        else t_sellMinToken1Amount(maxDeviation);
    }

    function test_sellMinWethAmount() public {
        if (pool.token0() == address(WETH)) t_sellMinToken0Amount(maxDeviation);
        else t_sellMinToken1Amount(maxDeviation);
    }

    function expectedWethAmount(uint256 daiAmount) public view returns (uint256 wethAmount) {
        wethAmount = daiAmount.mulDiv(uint256(chainlink.latestAnswer()), 10 ** chainlink.decimals());
    }

    function expectedDaiAmount(uint256 wethAmount) public view returns (uint256 daiAmount) {
        daiAmount = wethAmount.mulDiv(10 ** chainlink.decimals(), uint256(chainlink.latestAnswer()));
    }

    function expectedToken1Amount(uint256 token0Amount) public virtual override returns (uint256) {
        return token0Amount.mulDiv(uint256(chainlink.latestAnswer()), 10 ** chainlink.decimals());
    }

    function expectedToken0Amount(uint256 token1Amount) public virtual override returns (uint256) {
        return token1Amount.mulDiv(10 ** chainlink.decimals(), uint256(chainlink.latestAnswer()));
    }
}
