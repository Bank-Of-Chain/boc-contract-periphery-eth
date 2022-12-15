// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";

/// @title Mock3rdEthPool
/// @notice The mock contract of 3rdEthPool
/// @author Bank of Chain Protocol Inc
contract Mock3rdEthPool {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address private constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    receive() external payable {}

    /// @notice Deposits funds into Lido pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function deposit(address[] memory _assets, uint256[] memory _amounts) external payable {
        for (uint8 i = 0; i < _assets.length; i++) {
            if (_assets[i] != NativeToken.NATIVE_TOKEN) {
                IERC20Upgradeable(_assets[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                );
            }
        }
    }

    /// @notice Withdraws funds from Lido pool.
    /// @param _assets the address list of token to withdraw
    /// @param _amounts the amount list of token to withdraw
    function withdraw(uint256 _withdrawShares, uint256 _totalShares)
        external
        returns (address[] memory _assets, uint256[] memory _amounts)
    {
        _assets = new address[](3);
        _assets[0] = NativeToken.NATIVE_TOKEN;
        _assets[1] = stETH;
        _assets[2] = W_ETH;
        _amounts = new uint256[](3);
        _amounts[0] = (address(this).balance * _withdrawShares) / _totalShares;
        _amounts[1] =
            (IERC20Upgradeable(stETH).balanceOf(address(this)) * _withdrawShares) /
            _totalShares;
        _amounts[2] =
            (IERC20Upgradeable(W_ETH).balanceOf(address(this)) * _withdrawShares) /
            _totalShares;
        payable(msg.sender).transfer(_amounts[0]);
        IERC20Upgradeable(stETH).safeTransfer(msg.sender, _amounts[1]);
        IERC20Upgradeable(W_ETH).safeTransfer(msg.sender, _amounts[2]);
    }

    /// @notice Return the price of each share, default 1e18
    function pricePerShare() external view returns (uint256) {
        return 1e18;
    }

    /// @notice Gets the info of pending rewards
    /// @param _rewardsTokens The address list of reward tokens
    /// @param _pendingAmounts The amount list of reward tokens
    function getPendingRewards()
        external
        view
        returns (address[] memory _rewardsTokens, uint256[] memory _pendingAmounts)
    {}

    /// @notice Claims funds from Lido pool.
    /// @return _claimAmounts the amount list of token to claim
    function claim() external returns (uint256[] memory _claimAmounts) {}
}
