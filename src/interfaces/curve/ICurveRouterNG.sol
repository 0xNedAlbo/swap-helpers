// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface ICurveRouterNG {
    function exchange(
        address[11] memory routes,
        uint256[5][5] memory swapParams,
        uint256 amount,
        uint256 expected,
        address[5] memory pools,
        address receiver
    ) external returns (uint256);

    function get_dx(
        address[11] memory routes,
        uint256[5][5] memory swapParams,
        uint256 outAmount,
        address[5] memory pools,
        address[5] memory base_pools,
        address[5] memory base_tokens
    ) external view returns (uint256);

    function get_dy(
        address[11] memory routes,
        uint256[5][5] memory swapParams,
        uint256 inAmount,
        address[5] memory pools,
        address[5] memory base_pools,
        address[5] memory base_tokens
    ) external view returns (uint256);
}
