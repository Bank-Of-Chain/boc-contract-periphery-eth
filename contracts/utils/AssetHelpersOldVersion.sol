// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts~v3/math/SafeMath.sol";
import "@openzeppelin/contracts~v3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts~v3/token/ERC20/SafeERC20.sol";

/// @title AssetHelpers Contract
/// @notice A util contract for common token actions
abstract contract AssetHelpersOldVersion {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @dev Helper to approve a target account with the max amount of an asset.
    /// This is helpful for fully trusted contracts, such as adapters that
    /// interact with external protocol like Uniswap, Compound, etc.
    function __approveAssetMaxAsNeeded(
        address _asset,
        address _target,
        uint256 _neededAmount
    ) internal {
        if (ERC20(_asset).allowance(address(this), _target) < _neededAmount) {
            ERC20(_asset).safeApprove(_target, type(uint256).max);
        }
    }

    /// @dev Helper to get the balances of specified assets for a target
    function __getAssetBalances(address _target, address[] memory _assets)
    internal
    view
    returns (uint256[] memory _balances)
    {
        _balances = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            _balances[i] = ERC20(_assets[i]).balanceOf(_target);
        }

        return _balances;
    }

    /// @dev Helper to transfer full asset balances from a target to the current contract.
    /// Requires an adequate allowance for each asset granted to the current contract for the target.
    function __pullFullAssetBalances(address _target, address[] memory _assets)
    internal
    returns (uint256[] memory _amountsTransferred)
    {
        _amountsTransferred = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            ERC20 _assetContract = ERC20(_assets[i]);
            _amountsTransferred[i] = _assetContract.balanceOf(_target);
            if (_amountsTransferred[i] > 0) {
                _assetContract.safeTransferFrom(_target, address(this), _amountsTransferred[i]);
            }
        }

        return _amountsTransferred;
    }

    /// @dev Helper to transfer partial asset balances from a target to the current contract.
    /// Requires an adequate allowance for each asset granted to the current contract for the target.
    function __pullPartialAssetBalances(
        address _target,
        address[] memory _assets,
        uint256[] memory _amountsToExclude
    ) internal returns (uint256[] memory _amountsTransferred) {
        _amountsTransferred = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            ERC20 _assetContract = ERC20(_assets[i]);
            _amountsTransferred[i] = _assetContract.balanceOf(_target).sub(_amountsToExclude[i]);
            if (_amountsTransferred[i] > 0) {
                _assetContract.safeTransferFrom(_target, address(this), _amountsTransferred[i]);
            }
        }

        return _amountsTransferred;
    }

    /// @dev Helper to transfer full asset balances from the current contract to a target
    function __pushFullAssetBalances(address _target, address[] memory _assets)
    internal
    returns (uint256[] memory _amountsTransferred)
    {
        _amountsTransferred = new uint256[](_assets.length);
        for (uint256 i; i < _assets.length; i++) {
            ERC20 _assetContract = ERC20(_assets[i]);
            _amountsTransferred[i] = _assetContract.balanceOf(address(this));
            if (_amountsTransferred[i] > 0) {
                _assetContract.safeTransfer(_target, _amountsTransferred[i]);
            }
        }

        return _amountsTransferred;
    }
}
