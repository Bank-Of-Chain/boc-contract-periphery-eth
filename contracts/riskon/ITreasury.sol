// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import 'boc-contract-core/contracts/access-control/AccessControlMixin.sol';
import 'boc-contract-core/contracts/library/BocRoles.sol';

/// @title ITreasury
/// @author Bank of Chain Protocol Inc
interface ITreasury {

    /// @notice Return the '_token' balance of this contract.
    /// @param _token The token queryed
    /// @return The `_token` balance of this contract
    function balance(address _token) external view returns (uint256);

    /// @notice Withdraw '_amount' '_token' from this contract to '_receiver'
    /// @param _token The token to withdraw
    /// @param _receiver The receiver address to withdraw
    /// @param _amount The amount of token to withdraw
    function withdrawToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;

    /// @notice Withdraw ETH from this contract to '_receiver'
    /// @param _receiver The receiver address to withdraw
    /// @param _amount The amount of ETH to withdraw
    function withdrawETH(address payable _receiver, uint256 _amount) external payable;

    /// @notice Receive manage fee from a vault and swap from `_token` to Matic
    ///         and the recipient of this swap is keeper
    /// @param _token The fee token
    /// @param _feeAmount The fee amount
    function receiveManageFeeFromVault(address _token, uint256 _feeAmount) external payable;

    /// @notice Receive profits from a vault
    /// @param _token The profit token
    /// @param _profitAmount The profit amount
    function receiveProfitFromVault(address _token, uint256 _profitAmount) external payable;

}
