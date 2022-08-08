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

    bytes4[] private SWAP_METHOD_SELECTOR = [
    bytes4(keccak256('multiSwap(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('megaSwap(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('protectedMultiSwap(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('protectedMegaSwap(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('protectedSimpleSwap(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('simpleSwap(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('swapOnUniswap(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('swapOnUniswapFork(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('swapOnUniswapV2Fork(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('swapOnZeroXv2(bytes,(uint256,address,address,address))')),
    bytes4(keccak256('swapOnZeroXv4(bytes,(uint256,address,address,address))'))
    ];

    /// @notice Provides a constant string identifier for an adapter
    /// @return identifier_ An identifier string
    function identifier() external pure override returns (string memory identifier_) {
        return 'paraswap';
    }

    receive() external payable {
    }

    // EXTERNAL FUNCTIONS
    function swap(uint8 _method, bytes calldata _encodedCallArgs, IExchangeAdapter.SwapDescription calldata _sd) external payable override returns (uint256){
        require(_method < SWAP_METHOD_SELECTOR.length, 'ParaswapAdapter method out of range');
        bytes4 selector = SWAP_METHOD_SELECTOR[_method];
        bytes memory data = abi.encodeWithSelector(selector, _encodedCallArgs, _sd);
        bool success;
        bytes memory result;
        uint256 toTokenBefore = getTokenBalance(_sd.dstToken, address(_sd.receiver));
        (success, result) = address(this).delegatecall(data);

        if (success) {
            return getTokenBalance(_sd.dstToken, address(_sd.receiver)) - toTokenBefore;
        } else {
            revert(RevertReasonParser.parse(result, 'paraswap callBytes failed: '));
        }
    }

    function multiSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.SellData memory data) = abi.decode(_encodedCallArgs, (Utils.SellData));
        console.log('multiSwap');
        __validateFromTokenAmount(data.fromToken, _sd.srcToken);
        __validateToTokenAddress(data.path[data.path.length - 1].to, _sd.dstToken);
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;
        return __multiSwap(data);
    }

    function megaSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.MegaSwapSellData memory data) = abi.decode(_encodedCallArgs, (Utils.MegaSwapSellData));
        console.log('megaSwap');

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
        (Utils.SellData memory data) = abi.decode(_encodedCallArgs, (Utils.SellData));
        console.log('protectedMultiSwap');

        __validateFromTokenAmount(data.fromToken, _sd.srcToken);
        __validateToTokenAddress(data.path[data.path.length - 1].to, _sd.dstToken);
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;
        return __protectedMultiSwap(data);
    }

    function protectedMegaSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.MegaSwapSellData memory data) = abi.decode(_encodedCallArgs, (Utils.MegaSwapSellData));
        console.log('protectedMegaSwap');

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
        return __protectedMegaSwap(data);
    }

    function protectedSimpleSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.SimpleData memory data) = abi.decode(_encodedCallArgs, (Utils.SimpleData));
        console.log('protectedSimpleSwap');

        __validateFromTokenAmount(data.fromToken, _sd.srcToken);
        __validateToTokenAddress(data.toToken, _sd.dstToken);
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;
        return __protectedSimpleSwap(data);
    }

    function simpleSwap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (Utils.SimpleData memory data) = abi.decode(_encodedCallArgs, (Utils.SimpleData));
        console.log('simpleSwap');
        console.log('simpleSwap data.fromToken:%s', data.fromToken);

        __validateFromTokenAmount(data.fromToken, _sd.srcToken);
        __validateToTokenAddress(data.toToken, _sd.dstToken);
        // data.fromAmount can not be modify, even 1 (decimals in 18)
        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;
        return __simpleSwap(data);
    }

    function swapOnUniswap(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (uint256 amountIn,uint256 amountOutMin,address[] memory path) = __decodeSwapOnUniswapArgs(_encodedCallArgs);
        console.log('swapOnUniswap');

        address toToken = path[path.length - 1];
        __validateFromTokenAmount(path[0], _sd.srcToken);
        __validateToTokenAddress(toToken, _sd.dstToken);
        amountOutMin = _sd.amount.mul(amountOutMin).div(amountIn);
        amountIn = _sd.amount;

        uint256 toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnUniswap(
            amountIn,
            amountOutMin,
            path
        );
        uint256 amount = getTokenBalance(_sd.dstToken, address(this)).sub(toTokenBefore);
        console.log('=========transferToken amount========:%s', amount);
        toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(amount):IERC20(toToken).safeTransfer(_sd.receiver, amount);
        return amount;
    }

    function swapOnUniswapFork(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
        ) = __decodeSwapOnUniswapForkArgs(_encodedCallArgs);
        console.log('swapOnUniswapFork');

        address toToken = path[path.length - 1];

        __validateFromTokenAmount(path[0], _sd.srcToken);
        __validateToTokenAddress(toToken, _sd.dstToken);

        amountOutMin = _sd.amount.mul(amountOutMin).div(amountIn);
        amountIn = _sd.amount;
        //        amountIn = _sd.amount;
        //        amountOutMin = _sd.minReturn;
        uint256 toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnUniswapFork(
            factory,
            initCode,
            amountIn,
            amountOutMin,
            path
        );
        uint256 amount = getTokenBalance(_sd.dstToken, address(this)) - toTokenBefore;
        console.log('=========transferToken amount========:%s', amount);
        toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(amount):IERC20(toToken).safeTransfer(_sd.receiver, amount);
        return amount;
    }

    function swapOnUniswapV2Fork(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] memory pools
        ) = __decodeSwapOnUniswapV2ForkArgs(_encodedCallArgs);
        console.log('swapOnUniswapV2Fork _sd.dstToken:%s, tokenIn:%s', _sd.dstToken, tokenIn);
        console.log('swapOnUniswapV2Fork amountIn:%s, amountOutMin:%s', amountIn, amountOutMin);
        __validateFromTokenAmount(tokenIn, _sd.srcToken);
        //                __validateToTokenAddress(toToken, _sd);

        amountOutMin = _sd.amount.mul(amountOutMin).div(amountIn);
        amountIn = _sd.amount;
        //        amountIn = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnUniswapV2Fork(
            tokenIn,
            amountIn,
            amountOutMin,
            weth,
            pools
        );
        uint256 amount = getTokenBalance(_sd.dstToken, address(this)) - toTokenBefore;
        _sd.dstToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(amount):IERC20(_sd.dstToken).safeTransfer(_sd.receiver, amount);
        console.log('swapOnUniswapV2Fork transfer ok, _sd.receiver:%s, amount:%s, _sd.dstToken:%s', _sd.receiver, amount, _sd.dstToken);
        return amount;
    }

    function swapOnZeroXv2(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes memory payload
        ) = __decodeSwapOnZeroXv2Args(_encodedCallArgs);
        console.log('swapOnZeroXv2');

        __validateFromTokenAmount(fromToken, _sd.srcToken);
        __validateToTokenAddress(toToken, _sd.dstToken);

        amountOutMin = _sd.amount.mul(amountOutMin).div(fromAmount);
        fromAmount = _sd.amount;
        //        fromAmount = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnZeroXv2(
            IERC20(fromToken),
            IERC20(toToken),
            fromAmount,
            amountOutMin,
            exchange,
            payload
        );
        uint256 amount = getTokenBalance(_sd.dstToken, address(this)) - toTokenBefore;
        toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(amount):IERC20(toToken).safeTransfer(_sd.receiver, amount);
        return amount;
    }

    function swapOnZeroXv4(
        bytes calldata _encodedCallArgs,
        IExchangeAdapter.SwapDescription calldata _sd
    ) public payable returns (uint256){
        (
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes memory payload
        ) = __decodeSwapOnZeroXv4Args(_encodedCallArgs);
        console.log('swapOnZeroXv4');
        __validateFromTokenAmount(fromToken, _sd.srcToken);
        __validateToTokenAddress(toToken, _sd.dstToken);

        amountOutMin = _sd.amount.mul(amountOutMin).div(fromAmount);
        fromAmount = _sd.amount;
        //        fromAmount = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = getTokenBalance(_sd.dstToken, address(this));
        __swapOnZeroXv4(
            IERC20(fromToken),
            IERC20(toToken),
            fromAmount,
            amountOutMin,
            exchange,
            payload
        );
        uint256 amount = getTokenBalance(_sd.dstToken, address(this)) - toTokenBefore;
        toToken == NativeToken.NATIVE_TOKEN?payable(_sd.receiver).transfer(amount):IERC20(toToken).safeTransfer(_sd.receiver, amount);
        return amount;
    }

    function __decodeSwapOnZeroXv2Args(bytes memory _encodedCallArgs)
    private
    pure
    returns (
        address fromToken_,
        address toToken_,
        uint256 fromAmount_,
        uint256 amountOutMin_,
        address exchange_,
        bytes memory payload_
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
        address fromToken_,
        address toToken_,
        uint256 fromAmount_,
        uint256 amountOutMin_,
        address exchange_,
        bytes memory payload_
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
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
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
        address factory_,
        bytes32 initCode_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
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
        address tokenIn_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address weth_,
        uint256[] memory pools_
    )
    {
        return
        abi.decode(
            _encodedCallArgs,
            (address, uint256, uint256, address, uint256[])
        );
    }
}
