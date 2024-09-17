// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { console } from "forge-std/src/console.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { Test } from "forge-std/src/Test.sol";
import { IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IWETH } from "mock-tokens/src/interfaces/IWETH.sol";
import { Slippage } from "@src/utils/Slippage.sol";
import { ISwapHelper } from "@src/interfaces/ISwapHelper.sol";

abstract contract SwapHelperTest is StdCheats, Test {
    using Slippage for uint256;

    ISwapHelper public swapHelper;

    uint256 public forkId;
    address public user;

    address public router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint256 public token0FuzzMin;
    uint256 public token0FuzzMax;
    uint256 public token1FuzzMin;
    uint256 public token1FuzzMax;

    address public token0;
    address public token1;

    int24 public maxDeviation = 500;

    function setUp_swapHelper() public virtual returns (address);
    function setUp_fuzzer()
        public
        virtual
        returns (uint256 token0FuzzMin, uint256 token0FuzzMax, uint256 token1FuzzMin, uint256 token1FuzzMax);

    function token0AmountToUsd(uint256 token0Amount) public virtual returns (uint256);

    function token1AmountToUsd(uint256 token1Amount) public virtual returns (uint256);

    function usdAmountToToken0(uint256 usdAmount) public virtual returns (uint256);

    function usdAmountToToken1(uint256 usdAmount) public virtual returns (uint256);

    function setUp() public virtual {
        setUp_fork();
        setUp_user();
        swapHelper = ISwapHelper(setUp_swapHelper());
        (token0, token1) = setUp_tokens();
        (token0FuzzMin, token0FuzzMax, token1FuzzMin, token1FuzzMax) = setUp_fuzzer();
        maxDeviation = setUp_maxDeviation();
    }

    function setUp_tokens() public virtual returns (address, address) {
        return (swapHelper.token0(), swapHelper.token1());
    }

    function setUp_user() public virtual {
        user = address(1);
    }

    function setUp_fork() public virtual {
        string memory url = vm.rpcUrl("mainnet");
        uint256 blockNumber = vm.envUint("BLOCK");
        assertGt(blockNumber, 0, "Please set BLOCK env variable");
        forkId = vm.createSelectFork(url, blockNumber);
    }

    function setUp_maxDeviation() public virtual returns (int24) {
        return 500;
    }

    function test_00_tokens() public {
        emit log_named_string("token0", IERC20Metadata(token0).symbol());
        emit log_named_string("token1", IERC20Metadata(token1).symbol());
        uint8 token0Decimals = IERC20Metadata(token0).decimals();
        uint8 token1Decimals = IERC20Metadata(token1).decimals();
        emit log_named_decimal_uint("token0 -> usd price", token0AmountToUsd(10 ** token0Decimals), 18);
        emit log_named_decimal_uint("token1 -> usd price", token1AmountToUsd(10 ** token1Decimals), 18);
        emit log_named_decimal_uint("usd -> token0 price", usdAmountToToken0(1e18), token0Decimals);
        emit log_named_decimal_uint("usd -> token1 price", usdAmountToToken1(1e18), token1Decimals);
        emit log_named_decimal_uint(
            "token0 -> token1 price", expectedToken1Amount(10 ** token0Decimals), token1Decimals
        );
        emit log_named_decimal_uint(
            "token1 -> token0 price", expectedToken0Amount(10 ** token1Decimals), token0Decimals
        );
        emit log_named_decimal_int("maxDeviation %", maxDeviation, 2);
    }

    function test_00_fuzzer() public {
        emit log_named_decimal_uint("token0FuzzMin", token0FuzzMin, IERC20Metadata(token0).decimals());
        emit log_named_decimal_uint("token0FuzzMax", token0FuzzMax, IERC20Metadata(token0).decimals());
        emit log_named_decimal_uint("token1FuzzMin", token1FuzzMin, IERC20Metadata(token1).decimals());
        emit log_named_decimal_uint("token1FuzzMax", token1FuzzMax, IERC20Metadata(token1).decimals());
    }

    function test_10_previewBuyToken0(uint256 token0Amount) public virtual {
        vm.assume(token0Amount >= token0FuzzMin && token0Amount <= token0FuzzMax);
        uint256 token1Amount = swapHelper.previewBuyToken0(token0Amount);
        uint256 expectedAmount = expectedToken1Amount(token0Amount);
        int24 slippage = expectedAmount.slippage(token1Amount);
        require(slippage <= maxDeviation, "oracle deviation");
        require(slippage >= 0, "slippage below zero");
    }

    function test_10_previewBuyToken1(uint256 token1Amount) public virtual {
        vm.assume(token1Amount >= token1FuzzMin && token1Amount <= token1FuzzMax);
        uint256 token0Amount = swapHelper.previewBuyToken1(token1Amount);
        uint256 expectedAmount = expectedToken0Amount(token1Amount);
        int24 slippage = expectedAmount.slippage(token0Amount);
        require(slippage <= maxDeviation, "oracle deviation");
        require(slippage >= 0, "slippage below zero");
    }

    function test_10_previewSellToken0(uint256 token0Amount) public virtual {
        vm.assume(token0Amount >= token0FuzzMin && token0Amount <= token0FuzzMax);
        uint256 token1Amount = swapHelper.previewSellToken0(token0Amount);
        uint256 expectedAmount = expectedToken1Amount(token0Amount);
        int24 slippage = expectedAmount.slippage(token1Amount);
        require(slippage >= -maxDeviation, "oracle deviation");
        require(slippage <= 0, "slippage above zero");
    }

    function test_10_previewSellToken1(uint256 token1Amount) public virtual {
        vm.assume(token1Amount >= token1FuzzMin && token1Amount <= token1FuzzMax);
        uint256 token0Amount = swapHelper.previewSellToken1(token1Amount);
        uint256 expectedAmount = expectedToken0Amount(token1Amount);
        int24 slippage = expectedAmount.slippage(token0Amount);
        require(slippage >= -maxDeviation, "oracle deviation");
        require(slippage <= 0, "slippage above zero");
    }

    function test_20_buyToken0Amount(uint256 token0Amount) public virtual {
        vm.assume(token0Amount >= token0FuzzMin && token0Amount <= token0FuzzMax);
        uint256 maxToken1Amount = expectedToken1Amount(token0Amount).applySlippage(maxDeviation);
        setBalance(user, token1, maxToken1Amount);
        setBalance(user, token0, 0);
        vm.startPrank(user);
        IERC20(token1).approve(address(swapHelper), maxToken1Amount);
        uint256 amountIn = swapHelper.buyToken0(token0Amount, maxToken1Amount, user);
        vm.stopPrank();
        uint256 token0Balance = IERC20(token0).balanceOf(user);
        require(amountIn <= maxToken1Amount, "buy limit exceeded");
        require(token0Balance >= token0Amount, "received insufficient funds");
    }

    function test_20_buyToken1Amount(uint256 token1Amount) public virtual {
        vm.assume(token1Amount >= token1FuzzMin && token1Amount <= token1FuzzMax);
        uint256 maxToken0Amount = expectedToken0Amount(token1Amount).applySlippage(maxDeviation);
        setBalance(user, token0, maxToken0Amount);
        setBalance(user, token1, 0);
        vm.startPrank(user);
        IERC20(token0).approve(address(swapHelper), maxToken0Amount);
        uint256 amountIn = swapHelper.buyToken1(token1Amount, maxToken0Amount, user);
        vm.stopPrank();
        uint256 token1Balance = IERC20(token1).balanceOf(user);
        require(amountIn <= maxToken0Amount, "buy limit exceeded");
        require(token1Balance >= token1Amount, "received insufficient funds");
    }

    function test_20_sellToken0Amount(uint256 token0Amount) public virtual {
        vm.assume(token0Amount >= token0FuzzMin && token0Amount <= token0FuzzMax);
        uint256 minToken1Amount = expectedToken1Amount(token0Amount).applySlippage(-maxDeviation);
        setBalance(user, token0, token0Amount);
        setBalance(user, token1, 0);
        vm.startPrank(user);
        IERC20(token0).approve(address(swapHelper), token0Amount);
        uint256 amountOut = swapHelper.sellToken0(token0Amount, minToken1Amount, user);
        vm.stopPrank();
        uint256 token0Balance = IERC20(token0).balanceOf(user);
        uint256 token1Balance = IERC20(token1).balanceOf(user);
        require(amountOut == token1Balance, "swap result mismatch");
        require(token1Balance >= minToken1Amount, "sell limit exceeded");
        require(token0Balance == 0, "unspent funds");
    }

    function test_20_sellToken1Amount(uint256 token1Amount) public virtual {
        vm.assume(token1Amount >= token1FuzzMin && token1Amount <= token1FuzzMax);
        uint256 minToken0Amount = expectedToken0Amount(token1Amount).applySlippage(-maxDeviation);
        setBalance(user, token1, token1Amount);
        setBalance(user, token0, 0);
        vm.startPrank(user);
        IERC20(token1).approve(address(swapHelper), token1Amount);
        uint256 amountOut = swapHelper.sellToken1(token1Amount, minToken0Amount, user);
        vm.stopPrank();
        uint256 token0Balance = IERC20(token0).balanceOf(user);
        uint256 token1Balance = IERC20(token1).balanceOf(user);
        require(amountOut == token0Balance, "swap result mismatch");
        require(token0Balance >= minToken0Amount, "sell limit exceeded");
        require(token1Balance == 0, "unspent funds");
    }

    function test_30_buyToken0_revertsOnDeviationFromOracle() public virtual {
        uint256 bigAmount = token0FuzzMax * 10;
        uint256 token1Required = swapHelper.previewBuyToken0(bigAmount);
        uint256 token1MaxAmount = token1Required.applySlippage(-maxDeviation);
        setBalance(user, token1, token1Required);
        vm.prank(user);
        IERC20(token1).approve(address(swapHelper), token1Required);
        vm.expectRevert( /*bytes("!slippage")*/ );
        vm.prank(user);
        swapHelper.buyToken0(bigAmount, token1MaxAmount, user);
    }

    function test_30_buyToken1_revertsOnDeviationFromOracle() public virtual {
        uint256 bigAmount = token1FuzzMax * 10;
        uint256 token0Required = swapHelper.previewBuyToken1(bigAmount);
        uint256 token0MaxAmount = token0Required.applySlippage(-maxDeviation);
        setBalance(user, token0, token0Required);
        vm.prank(user);
        IERC20(token0).approve(address(swapHelper), token0Required);
        vm.expectRevert( /*bytes("!slippage")*/ );
        vm.prank(user);
        swapHelper.buyToken1(bigAmount, token0MaxAmount, user);
    }

    function test_30_sellToken0_revertsOnDeviationFromOracle() public virtual {
        uint256 bigAmount = token0FuzzMax * 10;
        uint256 token1MinAmount = expectedToken1Amount(bigAmount).applySlippage(-maxDeviation);
        setBalance(user, token0, bigAmount);
        vm.prank(user);
        IERC20(token0).approve(address(swapHelper), bigAmount);
        vm.expectRevert( /*bytes("!slippage")*/ );
        vm.prank(user);
        swapHelper.sellToken0(bigAmount, token1MinAmount, user);
    }

    function test_30_sellToken1_revertsOnDeviationFromOracle() public virtual {
        uint256 bigAmount = token1FuzzMax * 10;
        uint256 token0MinAmount = expectedToken0Amount(bigAmount).applySlippage(-maxDeviation);
        setBalance(user, token1, bigAmount);
        vm.prank(user);
        IERC20(token1).approve(address(swapHelper), bigAmount);
        vm.expectRevert( /*bytes("!slippage")*/ );
        vm.prank(user);
        swapHelper.sellToken1(bigAmount, token0MinAmount, user);
    }

    function setBalance(address owner, address token, uint256 amount) public {
        if (token == address(WETH)) {
            deal(owner, amount);
            deal(address(WETH), owner, 0);
            if (amount > 0) {
                vm.prank(owner);
                WETH.deposit{ value: amount }();
            }
        } else {
            deal(token, owner, amount);
        }
    }

    function expectedToken0Amount(uint256 token1Amount) public virtual returns (uint256 token0Amount) {
        uint256 usdAmount = token1AmountToUsd(token1Amount);
        token0Amount = usdAmountToToken0(usdAmount);
    }

    function expectedToken1Amount(uint256 token0Amount) public virtual returns (uint256 token1Amount) {
        uint256 usdAmount = token0AmountToUsd(token0Amount);
        token1Amount = usdAmountToToken1(usdAmount);
    }
}
