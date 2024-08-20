// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface ISwapper {
    event SwapFromAToB(address indexed sender, address indexed receiver, uint256 amountIn, uint256 amountOut);

    event SwapFromBToA(address indexed sender, address indexed receiver, uint256 amountIn, uint256 amountOut);

    function tokenA() external view returns (address);
    function tokenB() external view returns (address);

    function previewAtoB(uint256 amountA) external view returns (uint256);

    function previewBtoA(uint256 amountB) external view returns (uint256);

    function swapFromAtoB(uint256 amountA, uint256 minAmountB, address receiver) external returns (uint256);

    function swapFromBtoA(uint256 amountB, uint256 minAmountA, address receiver) external returns (uint256);
}
