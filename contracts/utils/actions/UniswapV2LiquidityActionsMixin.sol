// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '../../external/uniswap/IUniswapV2Router2.sol';
import '../AssetHelpers.sol';

/// @title UniswapV2ActionsMixin Contract
/// @notice Mixin contract for interacting with Uniswap v2
abstract contract UniswapV2LiquidityActionsMixin is AssetHelpers {

    address internal UniswapV2Router2;

    function _initializeUniswapV2(address _UniswapV2Router2) internal {
        UniswapV2Router2 = _UniswapV2Router2;
    }

    /// @dev Helper to add _liquidity
    function __uniswapV2Lend(
        address _recipient,
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) internal returns (uint _liquidity){
        __approveAssetMaxAsNeeded(_tokenA, UniswapV2Router2, _amountADesired);
        __approveAssetMaxAsNeeded(_tokenB, UniswapV2Router2, _amountBDesired);

        // Execute lend on Uniswap
        (, ,  _liquidity) = IUniswapV2Router2(UniswapV2Router2).addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            _amountAMin,
            _amountBMin,
            _recipient,
            __uniswapV2GetActionDeadline()
        );
    }

    /// @dev Helper to remove _liquidity
    function __uniswapV2Redeem(
        address _recipient,
        address _poolToken,
        uint256 _poolTokenAmount,
        address _tokenA,
        address _tokenB,
        uint256 _amountAMin,
        uint256 _amountBMin
    ) internal {
        __approveAssetMaxAsNeeded(_poolToken, UniswapV2Router2, _poolTokenAmount);

        // Execute redeem on Uniswap
        IUniswapV2Router2(UniswapV2Router2).removeLiquidity(
            _tokenA,
            _tokenB,
            _poolTokenAmount,
            _amountAMin,
            _amountBMin,
            _recipient,
            __uniswapV2GetActionDeadline()
        );
    }

    /// @dev Helper to get the deadline for a Uniswap V2 action in a standardized way
    function __uniswapV2GetActionDeadline() private view returns (uint256 _deadline) {
        return block.timestamp + 1;
    }

}
