// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import '../../../external/paraswap/IParaswapV5.sol';
import '../../../utils/AssetHelpersOldVersion.sol';

import 'hardhat/console.sol';

abstract contract ParaSwapV5ActionsMixin is AssetHelpersOldVersion {
    address internal constant PARA_SWAP_V5_AUGUSTUS_SWAPPER = address(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57);
    address internal constant PARA_SWAP_V5_TOKEN_TRANSFER_PROXY = address(0x216B4B4Ba9F3e719726886d34a177484278Bfcae);

    function __multiSwap(
        Utils.SellData memory _data
    ) internal returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);

        return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).multiSwap(_data);
    }

    function __megaSwap(
        Utils.MegaSwapSellData memory _data
    ) internal returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);

        return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).megaSwap(_data);
    }

    function __protectedMultiSwap(
        Utils.SellData memory _data
    ) internal returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);

        return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedMultiSwap(_data);
    }

    function __protectedMegaSwap(
        Utils.MegaSwapSellData memory _data
    ) internal returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);

        return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedMegaSwap(_data);
    }

    function __protectedSimpleSwap(
        Utils.SimpleData memory _data
    ) internal returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);

        return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).protectedSimpleSwap(_data);
    }

    function __simpleSwap(
        Utils.SimpleData memory _data
    ) internal returns (uint256){
        __approveAssetMaxAsNeeded(_data.fromToken, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _data.fromAmount);

        console.log('fromToken', _data.fromToken);
        console.log('toToken', _data.toToken);
        console.log('fromAmount', _data.fromAmount);
        console.log('toAmount', _data.toAmount);
        console.log('expectedAmount', _data.expectedAmount);
        return IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).simpleSwap(_data);
    }

    function __swapOnUniswap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) internal {
        __approveAssetMaxAsNeeded(_path[0], PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _amountIn);

        IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswap(_amountIn, _amountOutMin, _path);
    }

    function __swapOnUniswapFork(
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) internal {
        __approveAssetMaxAsNeeded(_path[0], PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _amountIn);

        IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswapFork(_factory, _initCode, _amountIn, _amountOutMin, _path);
    }

    function __swapOnUniswapV2Fork(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _weth,
        uint256[] memory _pools
    ) internal {
        __approveAssetMaxAsNeeded(_tokenIn, PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _amountIn);

        IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnUniswapV2Fork(
            _tokenIn,
            _amountIn,
            _amountOutMin,
            _weth,
            _pools
        );
    }

    function __swapOnZeroXv2(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
    ) internal {
        __approveAssetMaxAsNeeded(address(_fromToken), PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _fromAmount);

        IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnZeroXv2(
            _fromToken,
            _toToken,
            _fromAmount,
            _amountOutMin,
            _exchange,
            _payload
        );
    }

    function __swapOnZeroXv4(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
    ) internal{
        __approveAssetMaxAsNeeded(address(_fromToken), PARA_SWAP_V5_TOKEN_TRANSFER_PROXY, _fromAmount);

        IParaswapV5(PARA_SWAP_V5_AUGUSTUS_SWAPPER).swapOnZeroXv4(
            _fromToken,
            _toToken,
            _fromAmount,
            _amountOutMin,
            _exchange,
            _payload
        );
    }


    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `PARA_SWAP_V5_AUGUSTUS_SWAPPER` variable
    /// @return augustusSwapper_ The `PARA_SWAP_V5_AUGUSTUS_SWAPPER` variable value
    function getParaSwapV5AugustusSwapper() public pure returns (address augustusSwapper_) {
        return PARA_SWAP_V5_AUGUSTUS_SWAPPER;
    }

    /// @notice Gets the `PARA_SWAP_V5_TOKEN_TRANSFER_PROXY` variable
    /// @return tokenTransferProxy_ The `PARA_SWAP_V5_TOKEN_TRANSFER_PROXY` variable value
    function getParaSwapV5TokenTransferProxy() public pure returns (address tokenTransferProxy_) {
        return PARA_SWAP_V5_TOKEN_TRANSFER_PROXY;
    }
}
