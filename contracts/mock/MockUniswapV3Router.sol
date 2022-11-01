// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

/**
 * @title  MockUniswapV3Router
 * @dev    DO NOT USE IN PRODUCTION. This is only intended to be used
 *         for tests and lacks slippage and callback caller checks.
 */
contract MockUniswapV3Router is IUniswapV3MintCallback, IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;

    /// @notice Mints LP NFT and adds liquidity for the given recipient/tickLower/tickUpper position
    /// @param _pool One uniswap V3 liquidity pool
    /// @param _tickLower The lower tick of the position in which to add liquidity
    /// @param _tickUpper The upper tick of the position in which to add liquidity
    /// @param _amount The amount of liquidity to mint
    function mint(
        IUniswapV3Pool _pool,
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _amount
    ) external returns (uint256, uint256) {
        int24 _tickSpacing = _pool.tickSpacing();
        require(_tickLower % _tickSpacing == 0, "tickLower must be a multiple of tickSpacing");
        require(_tickUpper % _tickSpacing == 0, "tickUpper must be a multiple of tickSpacing");
        return _pool.mint(msg.sender, _tickLower, _tickUpper, _amount, abi.encode(msg.sender));
    }

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param _pool One uniswap V3 liquidity pool
    /// @param _zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param _amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
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

    /// @inheritdoc IUniswapV3MintCallback
    function uniswapV3MintCallback(
        uint256 _amount0Owed,
        uint256 _amount1Owed,
        bytes calldata _data
    ) external override {
        _callback(_amount0Owed, _amount1Owed, _data);
    }

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 _amount0Delta,
        int256 _amount1Delta,
        bytes calldata _data
    ) external override {
        uint256 _amount0 = _amount0Delta > 0 ? uint256(_amount0Delta) : 0;
        uint256 _amount1 = _amount1Delta > 0 ? uint256(_amount1Delta) : 0;
        _callback(_amount0, _amount1, _data);
    }

    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @param _amount0 The amount of token0 due to the pool for the minted liquidity
    /// @param _amount1 The amount of token1 due to the pool for the minted liquidity
    /// @param _data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function _callback(
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) internal {
        IUniswapV3Pool _pool = IUniswapV3Pool(msg.sender);
        address _payer = abi.decode(_data, (address));
        IERC20(_pool.token0()).safeTransferFrom(_payer, msg.sender, _amount0);
        IERC20(_pool.token1()).safeTransferFrom(_payer, msg.sender, _amount1);
    }
}
