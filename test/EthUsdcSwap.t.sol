// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { StdCheats, Test } from "forge-std/src/test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "mock-tokens/src/interfaces/IWETH.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IAggregator } from "@src/interfaces/chainlink/IAggregator.sol";

import { ISwapHelper } from "@src/interfaces/ISwapHelper.sol";
import { Slippage } from "@src/utils/Slippage.sol";
import { UniswapV3Helper } from "@src/UniswapV3Helper.sol";
import { UniswapV3HelperTest } from "./utils/UniswapV3HelperTest.sol";

contract EthUsdcSwapTest is UniswapV3HelperTest {
    using Math for uint256;
    using Slippage for uint256;

    address constant POOL_ADDRESS = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    IAggregator chainlink = IAggregator(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);

    int24 public maxOracleDeviation = 500;

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
        uint256 usdcMin = 1 * (10 ** 6);
        uint256 usdcMax = 100_000 * (10 ** 6);
        uint256 wethMin = 0.1 ether;
        uint256 wethMax = 100 ether;
        token0FuzzMin = token0 == USDC ? usdcMin : wethMin;
        token0FuzzMax = token0 == USDC ? usdcMax : wethMax;
        token1FuzzMin = token1 == USDC ? usdcMin : wethMin;
        token1FuzzMax = token1 == USDC ? usdcMax : wethMax;
    }

    function test_00_oracle() public {
        emit log_named_decimal_uint("USDC price", expectedWethAmount(1e6), 18);
        emit log_named_decimal_uint("WETH price", expectedUsdcAmount(1 ether), 6);
    }

    function test_10_previewBuyUsdc(uint256 usdcAmount) public {
        if (pool.token0() == USDC) t_previewBuyToken0(usdcAmount, maxOracleDeviation);
        else t_previewBuyToken1(usdcAmount, maxOracleDeviation);
    }

    function test_10_previewBuyWeth(uint256 wethAmount) public {
        if (pool.token0() == address(WETH)) t_previewBuyToken0(wethAmount, maxOracleDeviation);
        else t_previewBuyToken1(wethAmount, maxOracleDeviation);
    }

    function test_10_previewSellUsdc(uint256 usdcAmount) public {
        if (pool.token0() == USDC) t_previewSellToken0(usdcAmount, maxOracleDeviation);
        else t_previewSellToken1(usdcAmount, maxOracleDeviation);
    }

    function test_10_previewSellWeth(uint256 wethAmount) public {
        if (pool.token0() == address(WETH)) t_previewSellToken0(wethAmount, maxOracleDeviation);
        else t_previewSellToken1(wethAmount, maxOracleDeviation);
    }

    function test_20_buyMaxUsdcAmount() public {
        resetPoolBalances();
        if (pool.token0() == USDC) t_buyMaxToken0Amount(maxOracleDeviation);
        else t_buyMaxToken1Amount(maxOracleDeviation);
    }

    function test_20_buyMinUsdcAmount() public {
        resetPoolBalances();
        if (pool.token0() == USDC) t_buyMinToken0Amount(maxOracleDeviation);
        else t_buyMinToken1Amount(maxOracleDeviation);
    }

    function test_20_buyMaxWethAmount() public {
        resetPoolBalances();
        if (pool.token0() == address(WETH)) t_buyMaxToken0Amount(maxOracleDeviation);
        else t_buyMaxToken1Amount(maxOracleDeviation);
    }

    function test_20_buyMinWethAmount() public {
        resetPoolBalances();
        if (pool.token0() == address(WETH)) t_buyMinToken0Amount(maxOracleDeviation);
        else t_buyMinToken1Amount(maxOracleDeviation);
    }

    function test_20_sellMaxUsdcAmount() public {
        resetPoolBalances();
        if (pool.token0() == USDC) t_sellMinToken0Amount(maxOracleDeviation);
        else t_sellMinToken1Amount(maxOracleDeviation);
    }

    function test_20_sellMinUsdcAmount() public {
        resetPoolBalances();
        if (pool.token0() == USDC) t_sellMinToken0Amount(maxOracleDeviation);
        else t_sellMinToken1Amount(maxOracleDeviation);
    }

    function test_20_sellMaxWethAmount() public {
        resetPoolBalances();
        if (pool.token0() == address(WETH)) t_sellMinToken0Amount(maxOracleDeviation);
        else t_sellMinToken1Amount(maxOracleDeviation);
    }

    function test_20_sellMinWethAmount() public {
        resetPoolBalances();
        if (pool.token0() == address(WETH)) t_sellMinToken0Amount(maxOracleDeviation);
        else t_sellMinToken1Amount(maxOracleDeviation);
    }

    function test_30_buyUsdc_revertsOnDeviationFromOracle() public {
        if (pool.token0() == USDC) t_buyToken0_revertsOnDeviationFromOracle(maxOracleDeviation);
        else t_buyToken1_revertsOnDeviationFromOracle(500);
    }

    function test_30_buyWeth_revertsOnDeviationFromOracle() public {
        if (pool.token0() == address(WETH)) t_buyToken0_revertsOnDeviationFromOracle(maxOracleDeviation);
        else t_buyToken0_revertsOnDeviationFromOracle(500);
    }

    function test_30_sellUsdc_revertsOnDeviationFromOracle() public {
        if (pool.token0() == USDC) t_sellToken0_revertsOnDeviationFromOracle(500);
        else t_sellToken1_revertsOnDeviationFromOracle(500);
    }

    function test_30_sellWeth_revertsOnDeviationFromOracle() public {
        if (pool.token0() == address(WETH)) t_sellToken0_revertsOnDeviationFromOracle(500);
        else t_sellToken1_revertsOnDeviationFromOracle(500);
    }

    function expectedWethAmount(uint256 usdcAmount) public view returns (uint256 wethAmount) {
        usdcAmount = usdcAmount * (1e12);
        wethAmount = usdcAmount.mulDiv(uint256(chainlink.latestAnswer()), 10 ** chainlink.decimals());
    }

    function expectedUsdcAmount(uint256 wethAmount) public view returns (uint256 usdcAmount) {
        usdcAmount = wethAmount.mulDiv(10 ** chainlink.decimals(), uint256(chainlink.latestAnswer()));
        usdcAmount = usdcAmount / (1e12);
    }

    function expectedToken0Amount(uint256 token1Amount) public virtual override returns (uint256) {
        if (token0 == USDC) return expectedUsdcAmount(token1Amount);
        else return expectedWethAmount(token1Amount);
    }

    function expectedToken1Amount(uint256 token0Amount) public virtual override returns (uint256) {
        if (token1 == USDC) return expectedUsdcAmount(token0Amount);
        else return expectedWethAmount(token0Amount);
    }
}
