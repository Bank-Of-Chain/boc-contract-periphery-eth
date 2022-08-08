// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../external/curve/ICurveFi.sol";
import "../../external/uniswap/IUniswapV3.sol";
import "../../external/lido/IWstETH.sol";
import "../../external/weth/IWeth.sol";
import "./IETHExchanger.sol";
import "hardhat/console.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";

contract ETHExchanger is IETHExchanger {
    address constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
   
    address constant curve_eth_steth_pool = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address constant uniswap_v3_router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    constructor() {}

    fallback() external payable {}

    receive() external payable {}

    function eth2stEth(address receiver) public payable override returns (uint256 stEthAmount) {
        uint256 ethAmount = msg.value;
        assert(ethAmount > 0);
        uint256 stETHBalanceBefore = IERC20(stETH).balanceOf(address(this));
        ICurveFi(curve_eth_steth_pool).exchange{value: ethAmount}(0, 1, ethAmount, 0);
        uint256 stETHBalanceAfter = IERC20(stETH).balanceOf(address(this));
        stEthAmount = stETHBalanceAfter - stETHBalanceBefore;
        IERC20(stETH).transfer(receiver, stEthAmount);
        console.log("use %d eth swap to %d stEth", ethAmount, stEthAmount);
    }

    function stEth2Eth(address receiver, uint256 stEthAmount) public override returns (uint256 ethAmount) {
        IERC20(stETH).transferFrom(receiver, address(this), stEthAmount);
        IERC20(stETH).approve(curve_eth_steth_pool, 0);
        IERC20(stETH).approve(curve_eth_steth_pool, stEthAmount);
        uint256 balanceBefore = address(this).balance;
        ICurveFi(curve_eth_steth_pool).exchange(1, 0, stEthAmount, 0);
        uint256 balanceAfter = address(this).balance;
        ethAmount = balanceAfter - balanceBefore;
        payable(receiver).transfer(ethAmount);
        console.log("use %d steth swap to %d eth", stEthAmount, ethAmount);
    }

    function eth2wstEth(address receiver) public payable override returns (uint256 wstEthAmount) {
        // (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("eth2stEth()"));
        // assert(success);
        // uint256 stEthAmount = abi.decode(result, (uint256));
        uint256 ethAmount = msg.value;
        assert(ethAmount > 0);
        uint256 stETHBalanceBefore = IERC20(stETH).balanceOf(address(this));
        ICurveFi(curve_eth_steth_pool).exchange{value: ethAmount}(0, 1, ethAmount, 0);
        uint256 stETHBalanceAfter = IERC20(stETH).balanceOf(address(this));
        uint256 stEthAmount = stETHBalanceAfter - stETHBalanceBefore;
        console.log("stEthAmount2:", stEthAmount);

        IERC20(stETH).approve(wstETH, 0);
        IERC20(stETH).approve(wstETH, stEthAmount);
        wstEthAmount = IWstETH(wstETH).wrap(stEthAmount);

        IERC20(wstETH).transfer(receiver, wstEthAmount);
    }

    function wstEth2Eth(address receiver, uint256 wstEthAmount) public override returns (uint256 ethAmount) {
        IERC20(wstETH).transferFrom(receiver, address(this), wstEthAmount);
        uint256 wstETHBalance = IERC20(wstETH).balanceOf(address(this));
        assert(wstETHBalance >= wstEthAmount);
        uint256 stEthAmount = IWstETH(wstETH).unwrap(wstEthAmount);

        IERC20(stETH).approve(curve_eth_steth_pool, 0);
        IERC20(stETH).approve(curve_eth_steth_pool, stEthAmount);
        uint256 balanceBefore = address(this).balance;
        ICurveFi(curve_eth_steth_pool).exchange(1, 0, stEthAmount, 0);
        uint256 balanceAfter = address(this).balance;
        ethAmount = balanceAfter - balanceBefore;
        payable(receiver).transfer(ethAmount);
    }

    function eth2rEth(address receiver) public payable override returns (uint256 rEthAmount) {
        uint256 ethAmount = msg.value;
        assert(ethAmount > 0);
        IWeth(wETH).deposit{value: ethAmount}();
        uint256 wethAmount = IERC20(wETH).balanceOf(address(this));
        // address tokenIn;
        // address tokenOut;
        // uint24 fee;
        // address recipient;
        // uint256 deadline;
        // uint256 amountIn;
        // uint256 amountOutMinimum;
        // uint160 sqrtPriceLimitX96;
        IERC20(wETH).approve(uniswap_v3_router, 0);
        IERC20(wETH).approve(uniswap_v3_router, wethAmount);
        IUniswapV3.ExactInputSingleParams memory params = IUniswapV3.ExactInputSingleParams(wETH, rETH, 500, receiver, block.timestamp, wethAmount, 0, 0);
        rEthAmount = IUniswapV3(uniswap_v3_router).exactInputSingle(params);
        console.log("rEthAmount:", rEthAmount);
    }

    function rEth2Eth(address receiver, uint256 rEthAmount) public override returns (uint256 ethAmount) {
        IERC20(rETH).transferFrom(receiver, address(this), rEthAmount);
        uint256 rETHBalance = IERC20(rETH).balanceOf(address(this));
        assert(rETHBalance >= rEthAmount);

        IERC20(rETH).approve(uniswap_v3_router, 0);
        IERC20(rETH).approve(uniswap_v3_router, rEthAmount);
        IUniswapV3.ExactInputSingleParams memory params = IUniswapV3.ExactInputSingleParams(rETH, wETH, 500, address(this), block.timestamp, rEthAmount, 0, 0);
        uint256 wEthAmount = IUniswapV3(uniswap_v3_router).exactInputSingle(params);

        uint256 ethBalanceBefore = address(this).balance;
        IWeth(wETH).withdraw(wEthAmount);
        uint256 ethBalanceAfter = address(this).balance;
        ethAmount = ethBalanceAfter - ethBalanceBefore;
        payable(receiver).transfer(ethAmount);
    }

    function eth2wEth(address receiver) public payable override returns (uint256 wEthAmount) {
        uint256 ethAmount = msg.value;
        assert(ethAmount > 0);
        IWeth(wETH).deposit{value: ethAmount}();
        wEthAmount = IERC20(wETH).balanceOf(address(this));
        IERC20(wETH).transfer(receiver, wEthAmount);
    }

    function wEth2Eth(address receiver, uint256 wEthAmount) public override returns (uint256 ethAmount) {
        IERC20(wETH).transferFrom(receiver, address(this), wEthAmount);
        uint256 wETHBalance = IERC20(wETH).balanceOf(address(this));
        assert(wETHBalance >= wEthAmount);

        uint256 ethBalanceBefore = address(this).balance;
        IWeth(wETH).withdraw(wEthAmount);
        uint256 ethBalanceAfter = address(this).balance;
        ethAmount = ethBalanceAfter - ethBalanceBefore;
        payable(receiver).transfer(ethAmount);
    }

    function swap(
        address platform,
        uint8 _method,
        bytes calldata _data,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable override returns (uint256 toAmount) {
        if (_sd.srcToken == NativeToken.NATIVE_TOKEN && _sd.dstToken == stETH) {
            toAmount = eth2stEth(_sd.receiver);
        } else if (_sd.srcToken == NativeToken.NATIVE_TOKEN && _sd.dstToken == wETH) {
            toAmount = eth2wEth(_sd.receiver);
        } else if (_sd.srcToken == NativeToken.NATIVE_TOKEN && _sd.dstToken == wstETH) {
            toAmount = eth2wstEth(_sd.receiver);
        } else if (_sd.srcToken == NativeToken.NATIVE_TOKEN && _sd.dstToken == rETH) {
            toAmount = eth2rEth(_sd.receiver);
        } else if (_sd.dstToken == NativeToken.NATIVE_TOKEN && _sd.srcToken == stETH) {
            toAmount = stEth2Eth(_sd.receiver, _sd.amount);
        } else if (_sd.dstToken == NativeToken.NATIVE_TOKEN && _sd.srcToken == wETH) {
            toAmount = wEth2Eth(_sd.receiver, _sd.amount);
        } else if (_sd.dstToken == NativeToken.NATIVE_TOKEN && _sd.srcToken == wstETH) {
            toAmount = wstEth2Eth(_sd.receiver, _sd.amount);
        } else if (_sd.dstToken == NativeToken.NATIVE_TOKEN && _sd.srcToken == rETH) {
            toAmount = rEth2Eth(_sd.receiver, _sd.amount);
        } else {
            revert("Asset not available");
        }
    }
}
