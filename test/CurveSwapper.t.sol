// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { console } from "forge-std/src/console.sol";
import { Test } from "forge-std/src/test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISwapper } from "@src/interfaces/ISwapper.sol";
import { CurveSwapper } from "@src/CurveSwapper.sol";

import { IWETH } from "mock-tokens/src/interfaces/IWETH.sol";

contract CurveSwapperTest is Test {
    ISwapper public curveSwap;

    address public DAI_WHALE = 0xc2fE57936927D663937D83FD7D9a3C8Dbd233556;
    address public user;

    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function setUp() public {
        setUp_swapper();
        setUp_user();
    }

    function setUp_swapper() public {
        curveSwap = new CurveSwapper();
    }

    function setUp_user() public {
        user = vm.addr(1);
    }

    modifier withDaiAmount(uint256 daiAmount) {
        vm.prank(DAI_WHALE);
        IERC20(DAI).transfer(user, 100_000 ether);
        require(DAI.balanceOf(user) > 0);
        _;
    }

    modifier withWethAmount(uint256 wethAmount) {
        vm.deal(user, wethAmount);
        vm.prank(user);
        WETH.deposit{ value: wethAmount }();
        require(WETH.balanceOf(user) == wethAmount);
        _;
    }

    modifier withCurveRouter() {
        require(curveSwap.tokenA() == address(DAI), "Token A not DAI");
        require(curveSwap.tokenB() == address(WETH), "Token B not WETH");
        _;
    }

    function test_swapDaiToWeth() public withCurveRouter withDaiAmount(100_000 ether) {
        uint256 daiAmount = 100_000 ether;
        require(WETH.balanceOf(user) == 0);
        vm.startPrank(user);
        DAI.approve(address(curveSwap), daiAmount);
        curveSwap.swapFromAtoB(daiAmount, 1, user);
        vm.stopPrank();
        require(WETH.balanceOf(user) > 0);
    }

    function test_wethToDai() public withCurveRouter withWethAmount(10 ether) {
        require(DAI.balanceOf(user) == 0);
        uint256 wethAmout = 10 ether;
        vm.startPrank(user);
        WETH.approve(address(curveSwap), wethAmout);
        curveSwap.swapFromBtoA(wethAmout, 1, user);
        vm.stopPrank();
        require(DAI.balanceOf(user) > 0);
    }
}
