// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICurveRouterNG } from "@src/interfaces/curve/ICurveRouterNG.sol";
import { ISwapper } from "@src/interfaces/ISwapper.sol";

contract EthSwapper is ISwapper {
    using SafeERC20 for IERC20;

    address public immutable DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public threePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public tricryptoPool = 0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B;

    ICurveRouterNG public curveRouter = ICurveRouterNG(0x16C6521Dff6baB339122a0FE25a9116693265353);

    address public tokenA;
    address public tokenB;

    constructor() {
        tokenA = DAI;
        tokenB = WETH;
    }

    function previewAtoB(uint256 amountA) public view virtual override returns (uint256 amountOut) {
        address[11] memory routes = [
            DAI,
            threePool,
            address(USDC),
            tricryptoPool,
            WETH,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        uint256[5][5] memory swapParams = [
            [uint256(0), 1, 1, 1, 3],
            [uint256(0), 2, 1, 3, 3],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0]
        ];
        address[5] memory empty = [
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        amountOut = curveRouter.get_dy(routes, swapParams, amountA, empty);
    }

    function previewBtoA(uint256 amountB) public view virtual override returns (uint256 amountOut) {
        address[11] memory routes = [
            WETH,
            tricryptoPool,
            address(USDC),
            threePool,
            DAI,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        uint256[5][5] memory swapParams = [
            [uint256(2), 0, 1, 3, 3],
            [uint256(1), 0, 1, 1, 3],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0]
        ];
        address[5] memory empty = [
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        amountOut = curveRouter.get_dy(routes, swapParams, amountB, empty);
    }

    function swapFromAtoB(
        uint256 amountA,
        uint256 minAmountB,
        address receiver
    )
        public
        virtual
        override
        returns (uint256)
    {
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), amountA);
        address[11] memory routes = [
            DAI,
            threePool,
            address(USDC),
            tricryptoPool,
            WETH,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        uint256[5][5] memory swapParams = [
            [uint256(0), 1, 1, 1, 3],
            [uint256(0), 2, 1, 3, 3],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0]
        ];

        address[5] memory empty = [
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];

        IERC20(DAI).approve(address(curveRouter), amountA);
        uint256 amountOut = curveRouter.exchange(routes, swapParams, amountA, minAmountB, empty, receiver);
        emit SwapFromAToB(msg.sender, receiver, amountA, amountOut);
        return amountOut;
    }

    function swapFromBtoA(
        uint256 amountB,
        uint256 minAmountA,
        address receiver
    )
        public
        virtual
        override
        returns (uint256)
    {
        IERC20(WETH).safeTransferFrom(msg.sender, address(this), amountB);
        address[11] memory routes = [
            WETH,
            tricryptoPool,
            address(USDC),
            threePool,
            DAI,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        uint256[5][5] memory swapParams = [
            [uint256(2), 0, 1, 3, 3],
            [uint256(1), 0, 1, 1, 3],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0],
            [uint256(0), 0, 0, 0, 0]
        ];
        /*
        address[5] memory pools = [
            tricryptoPool,
            threePool,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        */
        address[5] memory empty = [
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        ];
        /*
        amountOut = curveRouter.get_dy(
            routes,
            swapParams,
            amountB,
            pools,
            empty,
            empty
        );
        */
        IERC20(WETH).approve(address(curveRouter), amountB);
        uint256 amountOut = curveRouter.exchange(routes, swapParams, amountB, minAmountA, empty, receiver);
        emit SwapFromAToB(msg.sender, receiver, amountB, amountOut);
        return amountOut;
    }
}
