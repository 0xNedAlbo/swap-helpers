// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface ISwapper {
    event SwapFromAToB(address indexed sender, address indexed receiver, uint256 amountIn, uint256 amountOut);

    event SwapFromBToA(address indexed sender, address indexed receiver, uint256 amountIn, uint256 amountOut);

    function tokenA() external view returns (address);
    function tokenB() external view returns (address);

    function previewSellA(uint256 amountA) external view returns (uint256);

    function previewSellB(uint256 amountB) external view returns (uint256);

    function previewBuyA(uint256 amountA) external view returns (uint256);

    function previewBuyB(uint256 amountB) external view returns (uint256);

    function sellA(uint256 amountA, uint256 minAmountB, address receiver) external returns (uint256);

    function sellB(uint256 amountB, uint256 minAmountA, address receiver) external returns (uint256);

    function buyA(uint256 amountA, uint256 maxAmountB, address receiver) external returns (uint256);

    function buyB(uint256 amountB, uint256 maxAmountA, address receiver) external returns (uint256);
}
