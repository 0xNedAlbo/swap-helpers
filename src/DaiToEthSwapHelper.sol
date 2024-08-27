// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { UniswapV3Helper } from "./UniswapV3Helper.sol";

contract DaiToEthSwapHelper is UniswapV3Helper {
    address constant POOL_ADDRESS = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;

    address immutable DAI;
    address immutable WETH;

    constructor() UniswapV3Helper(POOL_ADDRESS) {
        DAI = pool.token0();
        WETH = pool.token1();
    }

    function previewBuyDai(uint256 daiAmount) public returns (uint256) {
        if (DAI == pool.token0()) return previewBuyToken0(daiAmount);
        return previewBuyToken1(daiAmount);
    }

    function previewBuyWeth(uint256 wethAmount) public returns (uint256) {
        if (WETH == pool.token0()) return previewBuyToken0(wethAmount);
        return previewBuyToken1(wethAmount);
    }

    function previewSellDai(uint256 daiAmount) public returns (uint256) {
        if (DAI == pool.token0()) return previewSellToken0(daiAmount);
        return previewSellToken1(daiAmount);
    }

    function previewSellWeth(uint256 wethAmount) public returns (uint256) {
        if (WETH == pool.token0()) return previewSellToken0(wethAmount);
        return previewSellToken1(wethAmount);
    }

    function buyDai(uint256 daiAmount, uint256 maxWethAmount, address receiver) public returns (uint256) {
        if (DAI == pool.token0()) return buyToken0(daiAmount, maxWethAmount, receiver);
        return buyToken1(daiAmount, maxWethAmount, receiver);
    }

    function buyWeth(uint256 wethAmount, uint256 maxDaiAmount, address receiver) public returns (uint256) {
        if (DAI == pool.token0()) return buyToken0(wethAmount, maxDaiAmount, receiver);
        return buyToken1(wethAmount, maxDaiAmount, receiver);
    }

    function sellDai(uint256 daiAmount, uint256 minWethAmount, address receiver) public returns (uint256) {
        if (DAI == pool.token0()) return sellToken0(daiAmount, minWethAmount, receiver);
        return buyToken1(daiAmount, minWethAmount, receiver);
    }

    function sellWeth(uint256 wethAmount, uint256 minDaiAmount, address receiver) public returns (uint256) {
        if (DAI == pool.token0()) return sellToken0(wethAmount, minDaiAmount, receiver);
        return buyToken1(wethAmount, minDaiAmount, receiver);
    }
}
