// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import '../../external/paraswap/IParaswapV5.sol';

import 'hardhat/console.sol';
import './ExchangeHelpers.sol';

abstract contract ParaSwapV5ActionsMixin is ExchangeHelpers {
    address internal constant PARA_SWAP_V5_AUGUSTUS_SWAPPER = address(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);
    address internal constant PARA_SWAP_V5_TOKEN_TRANSFER_PROXY = address(0x216B4B4Ba9F3e719726886d34a177484278Bfcae);

    function __multiSwap(
        Utils.SellData memory _data
    ) public payable returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);
        if(_data.fromToken == NativeToken.NATIVE_TOKEN){
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).multiSwap{value: _data.fromAmount}(_data);
        }else{
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).multiSwap(_data);
        }
    }

    function __megaSwap(
        Utils.MegaSwapSellData memory _data
    ) public payable returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);
        if(_data.fromToken == NativeToken.NATIVE_TOKEN){
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).megaSwap{value: _data.fromAmount}(_data);
        }else{
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).megaSwap(_data);
        }
    }

    function __protectedMultiSwap(
        Utils.SellData memory _data
    ) public payable returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);
        if(_data.fromToken == NativeToken.NATIVE_TOKEN){
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedMultiSwap{value: _data.fromAmount}(_data);
        }else{
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedMultiSwap(_data);
        }
    }

    function __protectedMegaSwap(
        Utils.MegaSwapSellData memory _data
    ) public payable returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);
        if(_data.fromToken == NativeToken.NATIVE_TOKEN){
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedMegaSwap{value: _data.fromAmount}(_data);
        }else{
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedMegaSwap(_data);
        }
    }

    function __protectedSimpleSwap(
        Utils.SimpleData memory _data
    ) public payable returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);
        if(_data.fromToken == NativeToken.NATIVE_TOKEN){
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedSimpleSwap{value: _data.fromAmount}(_data);
        }else{
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedSimpleSwap(_data);
        }
    }

    function __simpleSwap(
        Utils.SimpleData memory _data
    ) public payable returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);
        if(_data.fromToken == NativeToken.NATIVE_TOKEN){
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).simpleSwap{value: _data.fromAmount}(_data);
        }else{
            return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).simpleSwap(_data);
        }
    }

    function __swapOnUniswap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public payable {
        __approveAssetMaxAsNeeded(_path[0], PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _amountIn);
        if(_path[0] == NativeToken.NATIVE_TOKEN){
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswap{value: _amountIn}(0, _amountOutMin, _path);
        }else{
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswap(_amountIn, _amountOutMin, _path);
        }
    }

    function __swapOnUniswapFork(
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) public payable {
        __approveAssetMaxAsNeeded(_path[0], PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _amountIn);
        if(_path[0] == NativeToken.NATIVE_TOKEN){
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswapFork{value: _amountIn}(_factory, _initCode, 0, _amountOutMin, _path);
        }else{
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswapFork(_factory, _initCode, _amountIn, _amountOutMin, _path);
        }
    }

    function __swapOnUniswapV2Fork(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _weth,
        uint256[] memory _pools
    ) public payable {
        __approveAssetMaxAsNeeded(_tokenIn, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _amountIn);
        if(_tokenIn == NativeToken.NATIVE_TOKEN){
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswapV2Fork{value: _amountIn}(_tokenIn, _amountIn, _amountOutMin, _weth, _pools);
        }else{
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswapV2Fork(_tokenIn, _amountIn, _amountOutMin, _weth, _pools);
        }
    }

    function __swapOnZeroXv2(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
    ) public payable {
        __approveAssetMaxAsNeeded(address(_fromToken), PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _fromAmount);
        if(address(_fromToken) == NativeToken.NATIVE_TOKEN){
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnZeroXv2{value: _fromAmount}(_fromToken, _toToken, _fromAmount, _amountOutMin, _exchange, _payload);
        }else{
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnZeroXv2(_fromToken, _toToken, _fromAmount, _amountOutMin, _exchange, _payload);
        }
    }

    function __swapOnZeroXv4(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
    ) public payable {
        __approveAssetMaxAsNeeded(address(_fromToken), PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _fromAmount);
        if(address(_fromToken) == NativeToken.NATIVE_TOKEN){
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnZeroXv4{value: _fromAmount}(_fromToken, _toToken, _fromAmount, _amountOutMin, _exchange, _payload);
        }else{
            IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnZeroXv4(_fromToken, _toToken, _fromAmount, _amountOutMin, _exchange, _payload);
        }
    }

    /// @notice Gets the `PARA_SWAP_V5_AUGUSTUS_SWAPPER` variable
    /// @return _augustusSwapper The `PARA_SWAP_V5_AUGUSTUS_SWAPPER` variable value
    function getParaSwapV5AugustusSwapper() public pure returns (address _augustusSwapper) {
        return PARA_SWAP_V5_AUGUSTUS_SWAPPER;
    }

    /// @notice Gets the `PARA_SWAP_V5_TOKEN_TRANSFER_PROXY` variable
    /// @return _tokenTransferProxy The `PARA_SWAP_V5_TOKEN_TRANSFER_PROXY` variable value
    function getParaSwapV5TokenTransferProxy() public pure returns (address _tokenTransferProxy) {
        return PARA_SWAP_V5_TOKEN_TRANSFER_PROXY;
    }
}
