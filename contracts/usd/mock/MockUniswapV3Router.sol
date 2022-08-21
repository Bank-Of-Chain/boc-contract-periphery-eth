// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

/**
 * @title  MockUniswapV3Router
 * @dev    DO NOT USE IN PRODUCTION. This is only intended to be used for tests and lacks slippage and callback caller checks.
 */
contract MockUniswapV3Router is IUniswapV3MintCallback, IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;

    function mint(
        IUniswapV3Pool _pool,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _amount
    ) external returns (uint256, uint256) {
        int24 _tickSpacing = _pool.tickSpacing();
        require(_tickLower % _tickSpacing == 0, "_tickLower must be a multiple of tickSpacing");
        require(_tickUpper % _tickSpacing == 0, "_tickUpper must be a multiple of tickSpacing");
        return _pool.mint(msg.sender, _tickLower, _tickUpper, _amount, abi.encode(msg.sender));
    }

    function swap(
        IUniswapV3Pool _pool,
        bool _zeroForOne,
        int256 _amountSpecified
    ) external returns (int256, int256) {
        return
            _pool.swap(
                msg.sender,
                _zeroForOne,
                _amountSpecified,
                _zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
                abi.encode(msg.sender)
            );
    }

    function uniswapV3MintCallback(
        uint256 _amount0Owed,
        uint256 _amount1Owed,
        bytes calldata _data
    ) external override {
        _callback(_amount0Owed, _amount1Owed, _data);
    }

    function uniswapV3SwapCallback(
        int256 _amount0Delta,
        int256 _amount1Delta,
        bytes calldata _data
    ) external override {
        uint256 _amount0 = _amount0Delta > 0 ? uint256(_amount0Delta) : 0;
        uint256 _amount1 = _amount1Delta > 0 ? uint256(_amount1Delta) : 0;
        _callback(_amount0, _amount1, _data);
    }

    function _callback(
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) internal {
        IUniswapV3Pool _pool = IUniswapV3Pool(msg.sender);
        address payer = abi.decode(_data, (address));
        IERC20(_pool.token0()).safeTransferFrom(payer, msg.sender, _amount0);
        IERC20(_pool.token1()).safeTransferFrom(payer, msg.sender, _amount1);
    }
}
