// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

enum SwapType {
    BuyToken0,
    BuyToken1,
    SellToken0,
    SellToken1,
    PreviewBuyToken0,
    PreviewBuyToken1,
    PreviewSellToken0,
    PreviewSellToken1
}

interface ISwapHelper {
    event SwapFromToken0(address indexed sender, address indexed receiver, uint256 amountIn, uint256 amountOut);

    event SwapFromToken1(address indexed sender, address indexed receiver, uint256 amountIn, uint256 amountOut);

    function token0() external view returns (address);
    function token1() external view returns (address);

    function previewSellToken0(uint256 amount0) external returns (uint256);

    function previewSellToken1(uint256 amount1) external returns (uint256);

    function previewBuyToken0(uint256 amount0) external returns (uint256);

    function previewBuyToken1(uint256 amount0) external returns (uint256);

    function buyToken0(uint256 amount0, uint256 maxAmount1, address receiver) external returns (uint256);

    function buyToken1(uint256 amount1, uint256 maxAmount0, address receiver) external returns (uint256);

    function sellToken0(uint256 amount0, uint256 minAmount1, address receiver) external returns (uint256);

    function sellToken1(uint256 amount1, uint256 minAmount0, address receiver) external returns (uint256);
}
