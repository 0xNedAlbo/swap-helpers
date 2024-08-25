// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { console } from "forge-std/src/console.sol";
import { StdCheats, Test } from "forge-std/src/test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH } from "mock-tokens/src/interfaces/IWETH.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IAggregator } from "@src/interfaces/chainlink/IAggregator.sol";

import { ISwapper } from "@src/interfaces/ISwapper.sol";
import { EthSwapper } from "@src/EthSwapper.sol";
import { SwapMath } from "@src/utils/SwapMath.sol";

contract EthSwapperTest is StdCheats, Test, SwapMath {
    using Math for uint256;

    ISwapper public ethSwap;

    address public user;

    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IAggregator chainlink = IAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function setUp() public {
        setUp_swapper();
        setUp_user();
    }

    function setUp_swapper() public {
        ethSwap = new EthSwapper();
    }

    function setUp_user() public {
        user = vm.addr(1);
    }

    modifier withCurveRouter() {
        require(ethSwap.tokenA() == address(DAI), "Token A not DAI");
        require(ethSwap.tokenB() == address(WETH), "Token B not WETH");
        _;
    }

    function test_previewSellDai() public view withCurveRouter {
        uint256 daiAmount = 300_000 ether;
        uint256 wethAmount = ethSwap.previewSellA(daiAmount);
        require(wethAmount > 0);
        uint256 amountExpected = daiAmount * 10 ** 8 / uint256(chainlink.latestAnswer());
        sellSlippage(amountExpected, wethAmount, 5_000_000);
    }

    function test_previewSellWeth() public view withCurveRouter {
        uint256 wethAmount = 10 ether;
        uint256 daiAmount = ethSwap.previewSellB(wethAmount);
        require(daiAmount > 0);
        uint256 amountExpected = wethAmount * uint256(chainlink.latestAnswer()) / 10 ** 8;
        sellSlippage(amountExpected, daiAmount, 5_000_000);
    }

    function test_previewBuyDai() public view withCurveRouter {
        uint256 daiAmount = 300_000 ether;
        uint256 wethAmount = ethSwap.previewBuyA(daiAmount);
        require(wethAmount > 0);
        uint256 amountExpected = daiAmount * 10 ** 8 / uint256(chainlink.latestAnswer());
        buySlippage(amountExpected, wethAmount, 5_000_000);
    }

    function test_previewBuyWeth() public view withCurveRouter {
        uint256 wethAmount = 10 ether;
        uint256 daiAmount = ethSwap.previewBuyB(wethAmount);
        require(daiAmount > 0);
        uint256 amountExpected = wethAmount * uint256(chainlink.latestAnswer()) / 10 ** 8;
        buySlippage(amountExpected, daiAmount, 5_000_000);
    }

    function test_sellDai() public withCurveRouter {
        uint256 daiAmount = 300_000 ether;
        deal(address(DAI), user, daiAmount);
        require(WETH.balanceOf(user) == 0);
        vm.startPrank(user);
        DAI.approve(address(ethSwap), daiAmount);
        ethSwap.sellA(daiAmount, 1, user);
        vm.stopPrank();
        require(WETH.balanceOf(user) > 0);
    }

    function test_sellWeth() public withCurveRouter {
        require(DAI.balanceOf(user) == 0);
        uint256 wethAmout = 10 ether;
        vm.deal(user, wethAmout);
        vm.startPrank(user);
        WETH.deposit{ value: wethAmout }();
        WETH.approve(address(ethSwap), wethAmout);
        ethSwap.sellB(wethAmout, 1, user);
        vm.stopPrank();
        require(DAI.balanceOf(user) > 0);
    }

    function test_buyDai() public withCurveRouter {
        uint256 daiAmount = 300_000 ether;
        require(DAI.balanceOf(user) == 0);
        vm.startPrank(user);
        uint256 wethAmount = ethSwap.previewBuyA(daiAmount);
        deal(user, wethAmount);
        WETH.deposit{ value: wethAmount }();
        WETH.approve(address(ethSwap), wethAmount);
        uint256 actualAmount = ethSwap.buyA(daiAmount, wethAmount, user);
        vm.stopPrank();
        require(DAI.balanceOf(user) > 0);
        buySlippage(daiAmount, actualAmount, 5_000_000);
    }

    function test_buyWeth() public withCurveRouter {
        uint256 wethAmount = 10 ether;
        require(WETH.balanceOf(user) == 0);
        uint256 daiAmount = ethSwap.previewBuyB(wethAmount);
        deal(address(DAI), user, daiAmount);
        vm.startPrank(user);
        DAI.approve(address(ethSwap), daiAmount);
        uint256 actualAmount = ethSwap.buyB(wethAmount, daiAmount, user);
        vm.stopPrank();
        require(WETH.balanceOf(user) > 0);
        buySlippage(wethAmount, actualAmount, 5_000_000);
    }
}
