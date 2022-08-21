// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "../utils/ParaSwapV5ActionsMixin.sol";
import "boc-contract-core/contracts/exchanges/IExchangeAdapter.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "boc-contract-core/contracts/library/RevertReasonParser.sol";
import "@openzeppelin/contracts~v3/math/SafeMath.sol";
import "hardhat/console.sol";

/// @title ParaSwapV4Adapter Contract
/// @author Enzyme Council <security@enzyme.finance>
/// @notice Adapter for interacting with ParaSwap (v4)
/// @dev Does not allow any protocol that collects protocol fees in ETH, e.g., 0x v3
contract ParaSwapV5Adapter is ParaSwapV5ActionsMixin, IExchangeAdapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes4[] private swapMethodSelector = [
    bytes4(keccak256("multiSwap(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("megaSwap(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("protectedMultiSwap(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("protectedMegaSwap(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("protectedSimpleSwap(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("simpleSwap(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("swapOnUniswap(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("swapOnUniswapFork(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("swapOnUniswapV2Fork(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("swapOnZeroXv2(bytes,(uint256,address,address,address))")),
    bytes4(keccak256("swapOnZeroXv4(bytes,(uint256,address,address,address))"))
    ];

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory) {
        return "paraswap";
    }

    receive() external payable {
    }

    // EXTERNAL FUNCTIONS
    function swap(uint8 _method, bytes calldata _encodedCallArgs, IExchangeAdapter.SwapDescription calldata _sd) external payable override returns (uint256){
        require(_method < swapMethodSelector.length, "ParaswapAdapter method out of range");
        bytes4 _selector = swapMethodSelector[_method];
        bytes memory _data = abi.encodeWithSelector(_selector, _encodedCallArgs, _sd);
        bool _success;
        bytes memory _result;
        uint256 _toTokenBefore = getTokenBalance(_sd.dstToken, address(_sd.receiver));
        (_success, _result) = address(this).delegatecall(_data);

        if (_success) {
            return getTokenBalance(_sd.dstToken, address(_sd.receiver)) - _toTokenBefore;
        } else {
            revert(RevertReasonParser.parse(_result, "paraswap callBytes failed: "));
        }
    }

    function multiSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.SellData memory _data) = abi.decode(_encodedCallArgs, (Utils.SellData));
        console.log("multiSwap");
        __validateFromTokenAmount(_data.fromToken, _sd.srcToken);
        __validateToTokenAddress(_data.path[_data.path.length - 1].to, _sd.dstToken);
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        _data.expectedAmount = _data.expectedAmount.mul(_sd.amount).div(_data.fromAmount);
        _data.toAmount = _sd.amount.mul(_data.toAmount).div(_data.fromAmount);
        _data.beneficiary = payable(_sd.receiver);
        _data.deadline = block.timestamp + 300;
        return __multiSwap(_data);
    }

    function megaSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.MegaSwapSellData memory data) = abi.decode(_encodedCallArgs, (Utils.MegaSwapSellData));
        console.log("megaSwap");

        __validateFromTokenAmount(data.fromToken, _sd.srcToken);
        for (uint256 i = 0; i < data.path.length; i++) {
            Utils.MegaSwapPath memory megaSwapPath = data.path[i];
            __validateToTokenAddress(megaSwapPath.path[megaSwapPath.path.length - 1].to, _sd.dstToken);
        }
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;
        return __megaSwap(data);
    }

    function protectedMultiSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.SellData memory _data) = abi.decode(_encodedCallArgs, (Utils.SellData));
        console.log("protectedMultiSwap");

        __validateFromTokenAmount(_data.fromToken, _sd.srcToken);
        __validateToTokenAddress(_data.path[_data.path.length - 1].to, _sd.dstToken);
        _data.expectedAmount = _data.expectedAmount.mul(_sd.amount).div(_data.fromAmount);
        _data.toAmount = _sd.amount.mul(_data.toAmount).div(_data.fromAmount);
        _data.beneficiary = payable(_sd.receiver);
        _data.deadline = block.timestamp + 300;
        return __protectedMultiSwap(_data);
    }

    function protectedMegaSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.MegaSwapSellData memory _data) = abi.decode(_encodedCallArgs, (Utils.MegaSwapSellData));
        console.log("protectedMegaSwap");

        __validateFromTokenAmount(_data.fromToken, _sd.srcToken);
        for (uint256 i = 0; i < _data.path.length; i++) {
            Utils.MegaSwapPath memory megaSwapPath = _data.path[i];
            __validateToTokenAddress(megaSwapPath.path[megaSwapPath.path.length - 1].to, _sd.dstToken);
        }
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        _data.expectedAmount = _data.expectedAmount.mul(_sd.amount).div(_data.fromAmount);
        _data.toAmount = _sd.amount.mul(_data.toAmount).div(_data.fromAmount);
        _data.beneficiary = payable(_sd.receiver);
        _data.deadline = block.timestamp + 300;
        return __protectedMegaSwap(_data);
    }

    function protectedSimpleSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.SimpleData memory _data) = abi.decode(_encodedCallArgs, (Utils.SimpleData));
        console.log("protectedSimpleSwap");

        __validateFromTokenAmount(_data.fromToken, _sd.srcToken);
        __validateToTokenAddress(_data.toToken, _sd.dstToken);
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        _data.expectedAmount = _data.expectedAmount.mul(_sd.amount).div(_data.fromAmount);
        _data.toAmount = _sd.amount.mul(_data.toAmount).div(_data.fromAmount);
        _data.beneficiary = payable(_sd.receiver);
        _data.deadline = block.timestamp + 300;
        return __protectedSimpleSwap(_data);
    }

    function simpleSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.SimpleData memory _data) = abi.decode(_encodedCallArgs, (Utils.SimpleData));
        console.log("simpleSwap");
        console.log("simpleSwap _data.fromToken:%s", _data.fromToken);

        __validateFromTokenAmount(_data.fromToken, _sd.srcToken);
        __validateToTokenAddress(_data.toToken, _sd.dstToken);
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        _data.expectedAmount = _data.expectedAmount.mul(_sd.amount).div(_data.fromAmount);
        _data.toAmount = _sd.amount.mul(_data.toAmount).div(_data.fromAmount);
        _data.beneficiary = payable(_sd.receiver);
        _data.deadline = block.timestamp + 300;
        return __simpleSwap(_data);
    }

    function swapOnUniswap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (uint256 _amountIn,uint256 _amountOutMin,address[] memory _path) = __decodeSwapOnUniswapArgs(_encodedCallArgs);
        console.log("swapOnUniswap");

        address _toToken = _path[_path.length - 1];
        __validateFromTokenAmount(_path[0], _sd.srcToken);
        __validateToTokenAddress(_toToken, _sd.dstToken);
        _amountOutMin = _sd.amount.mul(_amountOutMin).div(_amountIn);
        _amountIn = _sd.amount;

        uint256 _toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnUniswap(
            _amountIn,
            _amountOutMin,
            _path
        );
        uint256 _amount = getTokenBalance(_sd.dstToken, address(this)).sub(_toTokenBefore);
        console.log("=========transferToken _amount========:%s", _amount);
        _toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(_amount):IERC20(_toToken).safeTransfer(_sd.receiver, _amount);
        return _amount;

    }

    function swapOnUniswapFork(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address _factory,
        bytes32 _initCode,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
        ) = __decodeSwapOnUniswapForkArgs(_encodedCallArgs);
        console.log("swapOnUniswapFork");

        address _toToken = _path[_path.length - 1];

        __validateFromTokenAmount(_path[0], _sd.srcToken);
        __validateToTokenAddress(_toToken, _sd.dstToken);

        _amountOutMin = _sd.amount.mul(_amountOutMin).div(_amountIn);
        _amountIn = _sd.amount;
        
        uint256 _toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnUniswapFork(
            _factory,
            _initCode,
            _amountIn,
            _amountOutMin,
            _path
        );
        uint256 _amount = getTokenBalance(_sd.dstToken, address(this)) - _toTokenBefore;
        console.log("=========transferToken _amount========:%s", _amount);
        _toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(_amount):IERC20(_toToken).safeTransfer(_sd.receiver, _amount);
        return _amount;
    }

    function swapOnUniswapV2Fork(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _weth,
        uint256[] memory _pools
        ) = __decodeSwapOnUniswapV2ForkArgs(_encodedCallArgs);
        console.log("swapOnUniswapV2Fork _sd.dstToken:%s, _tokenIn:%s", _sd.dstToken, _tokenIn);
        console.log("swapOnUniswapV2Fork _amountIn:%s, _amountOutMin:%s", _amountIn, _amountOutMin);
        __validateFromTokenAmount(_tokenIn, _sd.srcToken);

        _amountOutMin = _sd.amount.mul(_amountOutMin).div(_amountIn);
        _amountIn = _sd.amount;

        uint256 _toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnUniswapV2Fork(
            _tokenIn,
            _amountIn,
            _amountOutMin,
            _weth,
            _pools
        );
        uint256 _amount = getTokenBalance(_sd.dstToken, address(this)) - _toTokenBefore;
        _sd.dstToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(_amount):IERC20(_sd.dstToken).safeTransfer(_sd.receiver, _amount);
        console.log("swapOnUniswapV2Fork transfer ok, _sd.receiver:%s, _amount:%s, _sd.dstToken:%s", _sd.receiver, _amount, _sd.dstToken);
        return _amount;
    }

    function swapOnZeroXv2(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
        ) = __decodeSwapOnZeroXv2Args(_encodedCallArgs);
        console.log("swapOnZeroXv2");

        __validateFromTokenAmount(_fromToken, _sd.srcToken);
        __validateToTokenAddress(_toToken, _sd.dstToken);

        _amountOutMin = _sd.amount.mul(_amountOutMin).div(_fromAmount);
        _fromAmount = _sd.amount;

        uint256 _toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnZeroXv2(
            IERC20(_fromToken),
            IERC20(_toToken),
            _fromAmount,
            _amountOutMin,
            _exchange,
            _payload
        );
        uint256 _amount = getTokenBalance(_sd.dstToken, address(this)) - _toTokenBefore;
        _toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(_amount):IERC20(_toToken).safeTransfer(_sd.receiver, _amount);
        return _amount;
    }

    function swapOnZeroXv4(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
        ) = __decodeSwapOnZeroXv4Args(_encodedCallArgs);
        console.log("swapOnZeroXv4");
        __validateFromTokenAmount(_fromToken, _sd.srcToken);
        __validateToTokenAddress(_toToken, _sd.dstToken);

        _amountOutMin = _sd.amount.mul(_amountOutMin).div(_fromAmount);
        _fromAmount = _sd.amount;

        uint256 _toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnZeroXv4(
            IERC20(_fromToken),
            IERC20(_toToken),
            _fromAmount,
            _amountOutMin,
            _exchange,
            _payload
        );
        uint256 _amount = getTokenBalance(_sd.dstToken, address(this)) - _toTokenBefore;
        _toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(_amount):IERC20(_toToken).safeTransfer(_sd.receiver, _amount);
        return _amount;
    }

    function __decodeSwapOnZeroXv2Args(bytes memory _encodedCallArgs)
    private
    pure
    returns (
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
    )
    {
        return
        abi.decode(
            _encodedCallArgs,
            (address, address, uint256, uint256, address, bytes)
        );
    }

    function __decodeSwapOnZeroXv4Args(bytes memory _encodedCallArgs)
    private
    pure
    returns (
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        uint256 _amountOutMin,
        address _exchange,
        bytes memory _payload
    )
    {
        return
        abi.decode(
            _encodedCallArgs,
            (address, address, uint256, uint256, address, bytes)
        );
    }

    function __decodeSwapOnUniswapArgs(bytes memory _encodedCallArgs)
    private
    pure
    returns (
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    )
    {
        return
        abi.decode(
            _encodedCallArgs,
            (uint256, uint256, address[])
        );
    }

    function __decodeSwapOnUniswapForkArgs(bytes memory _encodedCallArgs)
    private
    pure
    returns (
        address _factory_,
        bytes32 _initCode_,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    )
    {
        return
        abi.decode(
            _encodedCallArgs,
            (address, bytes32, uint256, uint256, address[])
        );
    }

    function __decodeSwapOnUniswapV2ForkArgs(bytes memory _encodedCallArgs)
    private
    pure
    returns (
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _weth_,
        uint256[] memory _pools_
    )
    {
        return
        abi.decode(
            _encodedCallArgs,
            (address, uint256, uint256, address, uint256[])
        );
    }
}
