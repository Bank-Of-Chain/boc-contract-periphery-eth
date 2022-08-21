// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/price-feeds/IValueInterpreter.sol";
import "boc-contract-core/contracts/strategy/IStrategy.sol";

contract MockVault is AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public valueInterpreter;

    constructor(address _accessControlProxy, address _valueInterpreter) {
        _initAccessControl(_accessControlProxy);
        valueInterpreter = _valueInterpreter;
    }

    function burn(uint256 _amount) external {}

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
    function redeem(address _strategy, uint256 _usdValue, uint256 _outputCode) external {
        uint256 _totalValue = IStrategy(_strategy).estimatedTotalAssets();
        if (_usdValue > _totalValue) {
            _usdValue = _totalValue;
        }
        IStrategy(_strategy).repay(_usdValue, _totalValue, _outputCode);
    }

    /// @notice Strategy report asset
    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts) external {}
}
