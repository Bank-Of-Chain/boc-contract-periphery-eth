// SPDX-License-Identifier: MIT

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <council@enzyme.finance>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.8.17;

import "../../external/uniswap/IUniswapV3SwapRouter.sol";
import "../AssetHelpers.sol";

/// @title UniswapV3ActionsMixin Contract
/// @author Enzyme Council <security@enzyme.finance>
/// @notice Mixin contract for interacting with Uniswap v3
abstract contract UniswapV3ActionsMixin is AssetHelpers {
    address internal constant UNISWAP_V3_ROUTER = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @dev Helper to execute a swap
    // UniswapV3 paths are packed encoded as (address(_pathAddresses[i]), uint24(_pathFees[i]), address(_pathAddresses[i + 1]), [...])
    // _pathFees[i] represents the fee for the pool between _pathAddresses(i) and _pathAddresses(i+1)
    function __uniswapV3Swap(
        address _recipient,
        address[] memory _pathAddresses,
        uint24[] memory _pathFees,
        uint256 _outgoingAssetAmount,
        uint256 _minIncomingAssetAmount
    ) internal returns (uint256) {
        __approveAssetMaxAsNeeded(_pathAddresses[0], UNISWAP_V3_ROUTER, _outgoingAssetAmount);

        bytes memory _encodedPath;

        for (uint256 i=0; i < _pathAddresses.length; i++) {
            if (i != _pathAddresses.length - 1) {
                _encodedPath = abi.encodePacked(_encodedPath, _pathAddresses[i], _pathFees[i]);
            } else {
                _encodedPath = abi.encodePacked(_encodedPath, _pathAddresses[i]);
            }
        }

        IUniswapV3SwapRouter.ExactInputParams memory _input = IUniswapV3SwapRouter
        .ExactInputParams({
        path: _encodedPath,
        recipient: _recipient,
        deadline: block.timestamp + 1,
        amountIn: _outgoingAssetAmount,
        amountOutMinimum: _minIncomingAssetAmount
        });

        // Execute fill
        return IUniswapV3SwapRouter(UNISWAP_V3_ROUTER).exactInput(_input);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `UNISWAP_V3_ROUTER` variable
    /// @return _router The `UNISWAP_V3_ROUTER` variable value
    function getUniswapV3Router() public pure returns (address _router) {
        return UNISWAP_V3_ROUTER;
    }
}
