// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "../utils/ParaSwapV5ActionsMixin.sol";
import "boc-contract-core/contracts/exchanges/IExchangeAdapter.sol";
import "../utils/ExchangeHelpers.sol";
import "@openzeppelin/contracts~v3/math/SafeMath.sol";
import "hardhat/console.sol";
import "boc-contract-core/contracts/library/RevertReasonParser.sol";

/// @title ParaSwapV4Adapter Contract
/// @author Enzyme Council <security@enzyme.finance>
/// @notice Adapter for interacting with ParaSwap (v4)
/// @dev Does not allow any protocol that collects protocol fees in ETH, e.g., 0x v3
contract ParaSwapV5Adapter is ParaSwapV5ActionsMixin, IExchangeAdapter, ExchangeHelpers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes4[] private SWAP_METHOD_SELECTOR = [
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
    function identifier() external pure override returns (string memory identifier_) {
        return "paraswap";
    }

    // EXTERNAL FUNCTIONS
    function swap(
        uint8 _method,
        bytes calldata _encodedCallArgs,
        SwapDescription calldata _sd
    ) external override returns (uint256) {
        require(_method < SWAP_METHOD_SELECTOR.length, "ParaswapAdapter method out of range");
        console.log("---paraswap swap method", _method);
        bytes4 selector = SWAP_METHOD_SELECTOR[_method];
        bytes memory data = abi.encodeWithSelector(selector, _encodedCallArgs, _sd);
        uint256 toTokenBefore = IERC20(_sd.dstToken).balanceOf(_sd.receiver);
        (bool success, bytes memory result) = address(this).delegatecall(data);
        if (success) {
            console.log("paraswap swap toToken %s exhangeAmount %d actual got amount %d", _sd.dstToken, abi.decode(result, (uint256)), IERC20(_sd.dstToken).balanceOf(_sd.receiver) - toTokenBefore);
            return IERC20(_sd.dstToken).balanceOf(_sd.receiver) - toTokenBefore;
        } else {
            revert(RevertReasonParser.parse(result, "callBytes failed: "));
        }
    }

    function multiSwap(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        Utils.SellData memory data = abi.decode(_encodedCallArgs, (Utils.SellData));

        __validateFromTokenAmount(data.fromToken, _sd);
        __validateToTokenAddress(data.path[data.path.length - 1].to, _sd);

        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.fromAmount = _sd.amount;
        //        data.fromAmount = _sd.amount;
        //        data.expectedAmount = _sd.expectedReturn;
        //        data.toAmount = _sd.minReturn;

        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;

        return __multiSwap(data);
    }

    function megaSwap(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        Utils.MegaSwapSellData memory data = abi.decode(
            _encodedCallArgs,
            (Utils.MegaSwapSellData)
        );

        __validateFromTokenAmount(data.fromToken, _sd);
        for (uint256 i = 0; i < data.path.length; i++) {
            Utils.MegaSwapPath memory megaSwapPath = data.path[i];
            __validateToTokenAddress(megaSwapPath.path[megaSwapPath.path.length - 1].to, _sd);
        }

        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.fromAmount = _sd.amount;
        //        data.fromAmount = _sd.amount;
        //        data.expectedAmount = _sd.expectedReturn;
        //        data.toAmount = _sd.minReturn;
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;

        return __megaSwap(data);
    }

    function protectedMultiSwap(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        Utils.SellData memory data = abi.decode(_encodedCallArgs, (Utils.SellData));

        __validateFromTokenAmount(data.fromToken, _sd);
        __validateToTokenAddress(data.path[data.path.length - 1].to, _sd);

        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.fromAmount = _sd.amount;
        //        data.fromAmount = _sd.amount;
        //        data.expectedAmount = _sd.expectedReturn;
        //        data.toAmount = _sd.minReturn;
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;

        return __protectedMultiSwap(data);
    }

    function protectedMegaSwap(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        Utils.MegaSwapSellData memory data = abi.decode(
            _encodedCallArgs,
            (Utils.MegaSwapSellData)
        );

        __validateFromTokenAmount(data.fromToken, _sd);
        for (uint256 i = 0; i < data.path.length; i++) {
            Utils.MegaSwapPath memory megaSwapPath = data.path[i];
            __validateToTokenAddress(megaSwapPath.path[megaSwapPath.path.length - 1].to, _sd);
        }

        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.fromAmount = _sd.amount;
        //        data.fromAmount = _sd.amount;
        //        data.expectedAmount = _sd.expectedReturn;
        //        data.toAmount = _sd.minReturn;
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;

        return __protectedMegaSwap(data);
    }

    function protectedSimpleSwap(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        Utils.SimpleData memory data = abi.decode(_encodedCallArgs, (Utils.SimpleData));

        __validateFromTokenAmount(data.fromToken, _sd);
        __validateToTokenAddress(data.toToken, _sd);

        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.fromAmount = _sd.amount;
        //        data.fromAmount = _sd.amount;
        //        data.expectedAmount = _sd.expectedReturn;
        //        data.toAmount = _sd.minReturn;
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;

        return __protectedSimpleSwap(data);
    }

    function simpleSwap(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        Utils.SimpleData memory data = abi.decode(_encodedCallArgs, (Utils.SimpleData));

        __validateFromTokenAmount(data.fromToken, _sd);
        __validateToTokenAddress(data.toToken, _sd);

        data.expectedAmount = data.expectedAmount.mul(_sd.amount).div(data.fromAmount);
        data.toAmount = _sd.amount.mul(data.toAmount).div(data.fromAmount);
        data.fromAmount = _sd.amount;
        //        data.fromAmount = _sd.amount;
        //        data.expectedAmount = _sd.expectedReturn;
        //        data.toAmount = _sd.minReturn;
        data.beneficiary = payable(_sd.receiver);
        data.deadline = block.timestamp + 300;

        return __simpleSwap(data);
    }

    function swapOnUniswap(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        (
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path
        ) = __decodeSwapOnUniswapArgs(_encodedCallArgs);

        address toToken = path[path.length - 1];

        __validateFromTokenAmount(path[0], _sd);
        __validateToTokenAddress(toToken, _sd);

        amountOutMin = _sd.amount.mul(amountOutMin).div(amountIn);
        amountIn = _sd.amount;

        //        amountIn = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = IERC20(toToken).balanceOf(address(this));
        __swapOnUniswap(amountIn, amountOutMin, path);
        uint256 amount = IERC20(toToken).balanceOf(address(this)).sub(toTokenBefore);

        IERC20(toToken).safeTransfer(_sd.receiver, amount);
        return amount;
    }

    function swapOnUniswapFork(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        (
            address factory,
            bytes32 initCode,
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path
        ) = __decodeSwapOnUniswapForkArgs(_encodedCallArgs);

        address toToken = path[path.length - 1];

        __validateFromTokenAmount(path[0], _sd);
        __validateToTokenAddress(toToken, _sd);

        amountOutMin = _sd.amount.mul(amountOutMin).div(amountIn);
        amountIn = _sd.amount;
        //        amountIn = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = IERC20(toToken).balanceOf(address(this));
        __swapOnUniswapFork(factory, initCode, amountIn, amountOutMin, path);
        uint256 amount = IERC20(toToken).balanceOf(address(this)) - toTokenBefore;

        IERC20(toToken).safeTransfer(_sd.receiver, amount);
        return amount;
    }

    function swapOnUniswapV2Fork(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        (
            address tokenIn,
            uint256 amountIn,
            uint256 amountOutMin,
            address weth,
            uint256[] memory pools
        ) = __decodeSwapOnUniswapV2ForkArgs(_encodedCallArgs);

        __validateFromTokenAmount(tokenIn, _sd);
        //        __validateToTokenAddress(toToken, _sd);

        amountOutMin = _sd.amount.mul(amountOutMin).div(amountIn);
        amountIn = _sd.amount;
        //        amountIn = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = IERC20(_sd.dstToken).balanceOf(address(this));
        __swapOnUniswapV2Fork(tokenIn, amountIn, amountOutMin, weth, pools);
        uint256 amount = IERC20(_sd.dstToken).balanceOf(address(this)) - toTokenBefore;

        IERC20(_sd.dstToken).safeTransfer(_sd.receiver, amount);
        return amount;
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
        return abi.decode(_encodedCallArgs, (uint256, uint256, address[]));
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
        return abi.decode(_encodedCallArgs, (address, bytes32, uint256, uint256, address[]));
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
        return abi.decode(_encodedCallArgs, (address, uint256, uint256, address, uint256[]));
    }

    function swapOnZeroXv2(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        (
            address fromToken,
            address toToken,
            uint256 fromAmount,
            uint256 amountOutMin,
            address exchange,
            bytes memory payload
        ) = __decodeSwapOnZeroXv2Args(_encodedCallArgs);

        __validateFromTokenAmount(fromToken, _sd);
        __validateToTokenAddress(toToken, _sd);

        amountOutMin = _sd.amount.mul(amountOutMin).div(fromAmount);
        fromAmount = _sd.amount;
        //        fromAmount = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = IERC20(toToken).balanceOf(address(this));
        __swapOnZeroXv2(
            IERC20(fromToken),
            IERC20(toToken),
            fromAmount,
            amountOutMin,
            exchange,
            payload
        );
        uint256 amount = IERC20(toToken).balanceOf(address(this)) - toTokenBefore;

        IERC20(toToken).safeTransfer(_sd.receiver, amount);
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
        return abi.decode(_encodedCallArgs, (address, address, uint256, uint256, address, bytes));
    }

    function swapOnZeroXv4(bytes calldata _encodedCallArgs, SwapDescription calldata _sd)
        public
        returns (uint256)
    {
        (
            address fromToken,
            address toToken,
            uint256 fromAmount,
            uint256 amountOutMin,
            address exchange,
            bytes memory payload
        ) = __decodeSwapOnZeroXv4Args(_encodedCallArgs);

        __validateFromTokenAmount(fromToken, _sd);
        __validateToTokenAddress(toToken, _sd);

        amountOutMin = _sd.amount.mul(amountOutMin).div(fromAmount);
        fromAmount = _sd.amount;
        //        fromAmount = _sd.amount;
        //        amountOutMin = _sd.minReturn;

        uint256 toTokenBefore = IERC20(toToken).balanceOf(address(this));
        __swapOnZeroXv4(
            IERC20(fromToken),
            IERC20(toToken),
            fromAmount,
            amountOutMin,
            exchange,
            payload
        );
        uint256 amount = IERC20(toToken).balanceOf(address(this)) - toTokenBefore;

        IERC20(toToken).safeTransfer(_sd.receiver, amount);
        return amount;
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
        return abi.decode(_encodedCallArgs, (address, address, uint256, uint256, address, bytes));
    }
}
