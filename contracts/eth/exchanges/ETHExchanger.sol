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
    address private constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address private constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address private constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address private constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
   
    address private constant CURVE_ETH_STETH_POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address private constant UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    constructor() {}

    receive() external payable {}

    fallback() external payable {}

    function eth2stEth(address _receiver) public payable override returns (uint256 _stEthAmount) {
        uint256 _ethAmount = msg.value;
        assert(_ethAmount > 0);
        uint256 _stETHBalanceBefore = IERC20(stETH).balanceOf(address(this));
        ICurveFi(CURVE_ETH_STETH_POOL).exchange{value: _ethAmount}(0, 1, _ethAmount, 0);
        uint256 _stETHBalanceAfter = IERC20(stETH).balanceOf(address(this));
        _stEthAmount = _stETHBalanceAfter - _stETHBalanceBefore;
        IERC20(stETH).transfer(_receiver, _stEthAmount);
        console.log("use %d eth swap to %d stEth", _ethAmount, _stEthAmount);
    }

    function stEth2Eth(address _receiver, uint256 _stEthAmount) public override returns (uint256 _ethAmount) {
        IERC20(stETH).transferFrom(_receiver, address(this), _stEthAmount);
        IERC20(stETH).approve(CURVE_ETH_STETH_POOL, 0);
        IERC20(stETH).approve(CURVE_ETH_STETH_POOL, _stEthAmount);
        uint256 _balanceBefore = address(this).balance;
        ICurveFi(CURVE_ETH_STETH_POOL).exchange(1, 0, _stEthAmount, 0);
        uint256 _balanceAfter = address(this).balance;
        _ethAmount = _balanceAfter - _balanceBefore;
        payable(_receiver).transfer(_ethAmount);
        console.log("use %d steth swap to %d eth", _stEthAmount, _ethAmount);
    }

    function eth2wstEth(address _receiver) public payable override returns (uint256 _wstEthAmount) {
        uint256 _ethAmount = msg.value;
        assert(_ethAmount > 0);
        uint256 _stETHBalanceBefore = IERC20(stETH).balanceOf(address(this));
        ICurveFi(CURVE_ETH_STETH_POOL).exchange{value: _ethAmount}(0, 1, _ethAmount, 0);
        uint256 _stETHBalanceAfter = IERC20(stETH).balanceOf(address(this));
        uint256 _stEthAmount = _stETHBalanceAfter - _stETHBalanceBefore;
        console.log("_stEthAmount2:", _stEthAmount);

        IERC20(stETH).approve(wstETH, 0);
        IERC20(stETH).approve(wstETH, _stEthAmount);
        _wstEthAmount = IWstETH(wstETH).wrap(_stEthAmount);

        IERC20(wstETH).transfer(_receiver, _wstEthAmount);
    }

    function wstEth2Eth(address _receiver, uint256 _wstEthAmount) public override returns (uint256 _ethAmount) {
        IERC20(wstETH).transferFrom(_receiver, address(this), _wstEthAmount);
        uint256 _wstETHBalance = IERC20(wstETH).balanceOf(address(this));
        assert(_wstETHBalance >= _wstEthAmount);
        uint256 _stEthAmount = IWstETH(wstETH).unwrap(_wstEthAmount);

        IERC20(stETH).approve(CURVE_ETH_STETH_POOL, 0);
        IERC20(stETH).approve(CURVE_ETH_STETH_POOL, _stEthAmount);
        uint256 _balanceBefore = address(this).balance;
        ICurveFi(CURVE_ETH_STETH_POOL).exchange(1, 0, _stEthAmount, 0);
        uint256 _balanceAfter = address(this).balance;
        _ethAmount = _balanceAfter - _balanceBefore;
        payable(_receiver).transfer(_ethAmount);
    }

    function eth2rEth(address _receiver) public payable override returns (uint256 _rEthAmount) {
        uint256 _ethAmount = msg.value;
        assert(_ethAmount > 0);
        IWeth(wETH).deposit{value: _ethAmount}();
        uint256 _wethAmount = IERC20(wETH).balanceOf(address(this));
        IERC20(wETH).approve(UNISWAP_V3_ROUTER, 0);
        IERC20(wETH).approve(UNISWAP_V3_ROUTER, _wethAmount);
        IUniswapV3.ExactInputSingleParams memory _params = IUniswapV3.ExactInputSingleParams(wETH, rETH, 500, _receiver, block.timestamp, _wethAmount, 0, 0);
        _rEthAmount = IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(_params);
        console.log("_rEthAmount:", _rEthAmount);
    }

    function rEth2Eth(address _receiver, uint256 _rEthAmount) public override returns (uint256 _ethAmount) {
        IERC20(rETH).transferFrom(_receiver, address(this), _rEthAmount);
        uint256 _rETHBalance = IERC20(rETH).balanceOf(address(this));
        assert(_rETHBalance >= _rEthAmount);

        IERC20(rETH).approve(UNISWAP_V3_ROUTER, 0);
        IERC20(rETH).approve(UNISWAP_V3_ROUTER, _rEthAmount);
        IUniswapV3.ExactInputSingleParams memory _params = IUniswapV3.ExactInputSingleParams(rETH, wETH, 500, address(this), block.timestamp, _rEthAmount, 0, 0);
        uint256 _wEthAmount = IUniswapV3(UNISWAP_V3_ROUTER).exactInputSingle(_params);

        uint256 _ethBalanceBefore = address(this).balance;
        IWeth(wETH).withdraw(_wEthAmount);
        uint256 _ethBalanceAfter = address(this).balance;
        _ethAmount = _ethBalanceAfter - _ethBalanceBefore;
        payable(_receiver).transfer(_ethAmount);
    }

    function eth2wEth(address _receiver) public payable override returns (uint256 _wEthAmount) {
        uint256 _ethAmount = msg.value;
        assert(_ethAmount > 0);
        IWeth(wETH).deposit{value: _ethAmount}();
        _wEthAmount = IERC20(wETH).balanceOf(address(this));
        IERC20(wETH).transfer(_receiver, _wEthAmount);
    }

    function wEth2Eth(address _receiver, uint256 _wEthAmount) public override returns (uint256 _ethAmount) {
        IERC20(wETH).transferFrom(_receiver, address(this), _wEthAmount);
        uint256 _wETHBalance = IERC20(wETH).balanceOf(address(this));
        assert(_wETHBalance >= _wEthAmount);

        uint256 _ethBalanceBefore = address(this).balance;
        IWeth(wETH).withdraw(_wEthAmount);
        uint256 _ethBalanceAfter = address(this).balance;
        _ethAmount = _ethBalanceAfter - _ethBalanceBefore;
        payable(_receiver).transfer(_ethAmount);
    }

    function swap(
        address _platform,
        uint8 _method,
        bytes calldata _data,
        IExchangeAdapter.SwapDescription calldata _sd
    ) external payable override returns (uint256 _toAmount) {
        address _nativeToken = NativeToken.NATIVE_TOKEN;
        if (_sd.srcToken == _nativeToken && _sd.dstToken == stETH) {
            _toAmount = eth2stEth(_sd.receiver);
        } else if (_sd.srcToken == _nativeToken && _sd.dstToken == wETH) {
            _toAmount = eth2wEth(_sd.receiver);
        } else if (_sd.srcToken == _nativeToken && _sd.dstToken == wstETH) {
            _toAmount = eth2wstEth(_sd.receiver);
        } else if (_sd.srcToken == _nativeToken && _sd.dstToken == rETH) {
            _toAmount = eth2rEth(_sd.receiver);
        } else if (_sd.dstToken == _nativeToken && _sd.srcToken == stETH) {
            _toAmount = stEth2Eth(_sd.receiver, _sd.amount);
        } else if (_sd.dstToken == _nativeToken && _sd.srcToken == wETH) {
            _toAmount = wEth2Eth(_sd.receiver, _sd.amount);
        } else if (_sd.dstToken == _nativeToken && _sd.srcToken == wstETH) {
            _toAmount = wstEth2Eth(_sd.receiver, _sd.amount);
        } else if (_sd.dstToken == _nativeToken && _sd.srcToken == rETH) {
            _toAmount = rEth2Eth(_sd.receiver, _sd.amount);
        } else {
            revert("Asset not available");
        }
    }
}
