// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title AssetHelpers
/// @notice A util contract for common token actions
abstract contract AssetHelpers {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Helper to approve a target account with the max amount of an asset.
    /// This is helpful for fully trusted contracts, such as adapters that
    /// interact with external protocol like Uniswap, Compound, etc.
    function __approveAssetMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        if (IERC20Upgradeable(_asset).allowance(address(this), _target) < _neededAmount) {
            IERC20Upgradeable(_asset).safeApprove(_target, 0);
            IERC20Upgradeable(_asset).safeApprove(_target, _neededAmount);
        }
    }

}
