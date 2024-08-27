// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { console } from "forge-std/src/console.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { Test } from "forge-std/src/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IWETH } from "mock-tokens/src/interfaces/IWETH.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { Slippage } from "@src/utils/Slippage.sol";
import { UniswapV3Helper } from "@src/UniswapV3Helper.sol";

abstract contract UniswapV3HelperTest is StdCheats, Test {
    using Slippage for uint256;

    UniswapV3Helper public swapHelper;

    uint256 public forkId;
    address public user;
    IUniswapV3Pool public pool;
    address public poolManager;

    IWETH public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint256 public token0FuzzMin;
    uint256 public token0FuzzMax;
    uint256 public token1FuzzMin;
    uint256 public token1FuzzMax;

    address public token0;
    address public token1;

    uint256 public poolBalance0;
    uint256 public poolBalance1;

    function setUp_swapHelper() public virtual returns (address);
    function setUp_fuzzer()
        public
        virtual
        returns (uint256 token0FuzzMin, uint256 token0FuzzMax, uint256 token1FuzzMin, uint256 token1FuzzMax);

    function expectedToken1Amount(uint256 token0Amount) public virtual returns (uint256);

    function expectedToken0Amount(uint256 token1Amount) public virtual returns (uint256);

    function setUp() public virtual {
        setUp_fork();
        setUp_user();
        swapHelper = UniswapV3Helper(setUp_swapHelper());
        pool = IUniswapV3Pool(setUp_pool());
        (token0, token1) = setUp_tokens();
        (token0FuzzMin, token0FuzzMax, token1FuzzMin, token1FuzzMax) = setUp_fuzzer();
        poolBalance0 = IERC20(token0).balanceOf(address(pool));
        poolBalance1 = IERC20(token1).balanceOf(address(pool));
    }

    function setUp_pool() public virtual returns (address) {
        return address(swapHelper.pool());
    }

    function setUp_tokens() public virtual returns (address, address) {
        return (pool.token0(), pool.token1());
    }

    function setUp_user() public virtual {
        user = address(1);
    }

    function setUp_fork() public virtual {
        string memory url = vm.rpcUrl("mainnet");
        uint256 blockNumber = vm.envUint("BLOCK");
        assertGt(blockNumber, 0, "Please set BLOCK envariable");
        forkId = vm.createSelectFork(url, blockNumber);
    }

    function t_previewBuyToken0(uint256 token0Amount, int24 maxDeviation) public {
        vm.assume(token0Amount >= token0FuzzMin && token0Amount <= token0FuzzMax);
        uint256 token1Amount = swapHelper.previewBuyToken0(token0Amount);
        uint256 expectedAmount = expectedToken1Amount(token0Amount);
        int24 slippage = expectedAmount.slippage(token1Amount);
        require(slippage <= maxDeviation, "oracle deviation");
    }

    function t_previewBuyToken1(uint256 token1Amount, int24 maxDeviation) public {
        vm.assume(token1Amount >= token1FuzzMin && token1Amount <= token1FuzzMax);
        uint256 token0Amount = swapHelper.previewBuyToken1(token1Amount);
        uint256 expectedAmount = expectedToken0Amount(token1Amount);
        int24 slippage = expectedAmount.slippage(token0Amount);
        require(slippage <= maxDeviation, "oracle deviation");
    }

    function t_previewSellToken0(uint256 token0Amount, int24 maxDeviation) public {
        emit log_named_decimal_uint("token0Amount: ", token0Amount, 6);
        emit log_named_decimal_uint("token0FuzzMax: ", token0FuzzMax, 6);
        vm.assume(token0Amount >= token0FuzzMin && token0Amount <= token0FuzzMax);
        uint256 token1Amount = swapHelper.previewSellToken0(token0Amount);
        uint256 expectedAmount = expectedToken1Amount(token0Amount);
        int24 slippage = expectedAmount.slippage(token1Amount);
        require(slippage >= -maxDeviation, "oracle deviation");
    }

    function t_previewSellToken1(uint256 token1Amount, int24 maxDeviation) public {
        vm.assume(token1Amount >= token1FuzzMin && token1Amount <= token1FuzzMax);
        uint256 token0Amount = swapHelper.previewSellToken1(token1Amount);
        uint256 expectedAmount = expectedToken0Amount(token1Amount);
        int24 slippage = expectedAmount.slippage(token0Amount);
        require(slippage >= -maxDeviation, "oracle deviation");
    }

    function t_buyToken0Amount(uint256 token0Amount, int24 maxDeviation) public {
        vm.assume(token0Amount >= token0FuzzMin && token0Amount <= token0FuzzMax);
        uint256 maxToken1Amount = expectedToken1Amount(token0Amount).applySlippage(maxDeviation);
        setBalance(user, token1, maxToken1Amount);
        setBalance(user, token0, 0);
        vm.startPrank(user);
        IERC20(pool.token1()).approve(address(swapHelper), maxToken1Amount);
        uint256 amountIn = swapHelper.buyToken0(token0Amount, maxToken1Amount, user);
        vm.stopPrank();
        uint256 token0Balance = IERC20(token0).balanceOf(user);
        require(amountIn <= maxToken1Amount, "buy limit exceeded");
        require(token0Balance >= token0Amount, "received insufficient funds");
    }

    function t_buyMinToken0Amount(int24 maxDeviation) public {
        t_buyToken0Amount(token0FuzzMin, maxDeviation);
    }

    function t_buyMaxToken0Amount(int24 maxDeviation) public {
        t_buyToken0Amount(token0FuzzMax, maxDeviation);
    }

    function t_buyToken1Amount(uint256 token1Amount, int24 maxDeviation) public {
        vm.assume(token1Amount >= token1FuzzMin && token1Amount <= token1FuzzMax);
        uint256 maxToken0Amount = expectedToken0Amount(token1Amount).applySlippage(maxDeviation);
        setBalance(user, token0, maxToken0Amount);
        setBalance(user, token1, 0);
        vm.startPrank(user);
        IERC20(pool.token0()).approve(address(swapHelper), maxToken0Amount);
        uint256 amountIn = swapHelper.buyToken1(token1Amount, maxToken0Amount, user);
        vm.stopPrank();
        uint256 token1Balance = IERC20(token1).balanceOf(user);
        require(amountIn <= maxToken0Amount, "buy limit exceeded");
        require(token1Balance >= token1Amount, "received insufficient funds");
    }

    function t_buyMinToken1Amount(int24 maxDeviation) public {
        t_buyToken1Amount(token1FuzzMin, maxDeviation);
    }

    function t_buyMaxToken1Amount(int24 maxDeviation) public {
        t_buyToken1Amount(token1FuzzMax, maxDeviation);
    }

    function t_sellToken0Amount(uint256 token0Amount, int24 maxDeviation) public {
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

    function t_sellMinToken0Amount(int24 maxDeviation) public {
        t_sellToken0Amount(token0FuzzMin, maxDeviation);
    }

    function t_sellMaxToken0Amount(int24 maxDeviation) public {
        t_sellToken0Amount(token0FuzzMax, maxDeviation);
    }

    function t_sellToken1Amount(uint256 token1Amount, int24 maxDeviation) public {
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

    function t_sellMinToken1Amount(int24 maxDeviation) public {
        t_sellToken1Amount(token1FuzzMin, maxDeviation);
    }

    function t_sellMaxToken1Amount(int24 maxDeviation) public {
        t_sellToken1Amount(token1FuzzMax, maxDeviation);
    }

    function t_buyToken0_revertsOnDeviationFromOracle(int24 maxDeviation) public {
        resetPoolBalances();
        uint256 halfPool = poolBalance0 / 2;
        uint256 token1MaxAmount = expectedToken1Amount(halfPool).applySlippage(maxDeviation);
        uint256 token1Required = swapHelper.previewBuyToken0(halfPool);
        setBalance(user, token1, token1Required);
        vm.prank(user);
        IERC20(token1).approve(address(swapHelper), token1Required);
        vm.expectRevert(bytes("!slippage"));
        vm.prank(user);
        swapHelper.buyToken0(halfPool, token1MaxAmount, user);
    }

    function t_buyToken1_revertsOnDeviationFromOracle(int24 maxDeviation) public {
        resetPoolBalances();
        uint256 halfPool = poolBalance1 / 2;
        uint256 token0MaxAmount = expectedToken0Amount(halfPool).applySlippage(maxDeviation);
        uint256 token0Required = swapHelper.previewBuyToken1(halfPool);
        setBalance(user, token1, token0Required);
        vm.prank(user);
        IERC20(token0).approve(address(swapHelper), token0Required);
        vm.expectRevert(bytes("!slippage"));
        vm.prank(user);
        swapHelper.buyToken1(halfPool, token0MaxAmount, user);
    }

    function t_sellToken0_revertsOnDeviationFromOracle(int24 maxDeviation) public {
        resetPoolBalances();
        uint256 bigAmount = poolBalance0 * 2;
        uint256 token1MinAmount = expectedToken1Amount(bigAmount).applySlippage(-maxDeviation);
        setBalance(user, token0, bigAmount);
        vm.prank(user);
        IERC20(token0).approve(address(swapHelper), bigAmount);
        vm.expectRevert(bytes("!slippage"));
        vm.prank(user);
        swapHelper.sellToken0(bigAmount, token1MinAmount, user);
    }

    function t_sellToken1_revertsOnDeviationFromOracle(int24 maxDeviation) public {
        resetPoolBalances();
        uint256 bigAmount = poolBalance1 * 1400 / 1000;
        uint256 token0MinAmount = expectedToken0Amount(bigAmount).applySlippage(maxDeviation);
        setBalance(user, token1, bigAmount);
        vm.prank(user);
        IERC20(token1).approve(address(swapHelper), bigAmount);
        vm.expectRevert(bytes("!slippage"));
        vm.prank(user);
        swapHelper.sellToken1(bigAmount, token0MinAmount, user);
    }

    function resetPoolBalances() public {
        uint256 currentBalance = IERC20(token0).balanceOf(address(pool));
        uint256 delta;
        if (currentBalance < poolBalance0) {
            delta = poolBalance0 - currentBalance;
            setBalance(poolManager, token0, delta);
            vm.prank(poolManager);
            IERC20(token0).approve(address(swapHelper), delta);
            vm.prank(poolManager);
            swapHelper.sellToken0(delta, 1, poolManager);
        } else if (currentBalance > poolBalance0) {
            delta = currentBalance - poolBalance0;
            uint256 token1Quote = swapHelper.previewBuyToken0(delta);
            token1Quote = token1Quote.applySlippage(5000);
            setBalance(poolManager, token1, token1Quote);
            vm.prank(poolManager);
            IERC20(token1).approve(address(swapHelper), token1Quote);
            vm.prank(poolManager);
            swapHelper.buyToken0(delta, token1Quote, poolManager);
        }
        currentBalance = IERC20(token0).balanceOf(address(pool));
        require(currentBalance == poolBalance0, "pool reset failed");
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
}
