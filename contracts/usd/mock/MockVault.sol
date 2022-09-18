// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/price-feeds/IValueInterpreter.sol";
import "boc-contract-core/contracts/strategy/IStrategy.sol";

/// @title MockVault
/// @notice The mock contract of Vault
/// @author Bank of Chain Protocol Inc
contract MockVault is AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public valueInterpreter;

    constructor(address _accessControlProxy, address _valueInterpreter) {
        _initAccessControl(_accessControlProxy);
        valueInterpreter = _valueInterpreter;
    }

    /// @notice Mock function for burning
    /// @param _amount Amount of USDi to burn
    function burn(uint256 _amount) external {}

    /// @notice Allocate funds in Vault to strategies.
    /// @param _strategy The specified strategy to lend
    /// @param _assets Address of the asset being lended
    /// @param _amounts Amount of the asset being lended
    function lend(
        address _strategy,
        address[] memory _assets,
        uint256[] memory _amounts
    ) external {
        for (uint8 i = 0; i < _assets.length; i++) {
            address _token = _assets[i];
            uint256 _amount = _amounts[i];
            IERC20Upgradeable _item = IERC20Upgradeable(_token);
            require(_item.balanceOf(address(this)) >= _amount, "Insufficient tokens");
            _item.safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).borrow(_assets, _amounts);
    }

    /// @notice Withdraw the funds from specified strategy.
    /// @param _strategy The specified strategy to redeem
    /// @param _usdValue The amount to redeem in USD 
    /// @param _outputCode The code of output 
    function redeem(address _strategy, uint256 _usdValue, uint256 _outputCode) external {
        uint256 _totalValue = IStrategy(_strategy).estimatedTotalAssets();
        if (_usdValue > _totalValue) {
            _usdValue = _totalValue;
        }
        IStrategy(_strategy).repay(_usdValue, _totalValue, _outputCode);
    }

    /// @dev Report the current asset of strategy caller
    /// @param _rewardTokens The reward token list
    /// @param _claimAmounts The claim amount list
    /// Emits a {StrategyReported} event.
    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts) external {}
}
