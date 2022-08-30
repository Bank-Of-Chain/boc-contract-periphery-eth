// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "../oracle/IPriceOracleConsumer.sol";
import "../strategies/IETHStrategy.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";

contract MockETHVault is AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public priceProvider;

    event StrategyReported(
        address indexed _strategy,
        uint256 _gain,
        uint256 _loss,
        uint256 _lastStrategyTotalDebt,
        uint256 _nowStrategyTotalDebt,
        address[] _rewardTokens,
        uint256[] _claimAmounts,
        uint256 _type
    );

    constructor(address _accessControlProxy, address _valueInterpreter) {
        _initAccessControl(_accessControlProxy);
        priceProvider = _valueInterpreter;
    }

    receive() external payable {}

    fallback() external payable {}

    function treasury() external view returns (address) {
        return address(this);
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
            if (_token == NativeToken.NATIVE_TOKEN) {
                payable(address(_strategy)).transfer(_amount);
            } else {
                IERC20Upgradeable _item = IERC20Upgradeable(_token);
                _item.safeTransfer(_strategy, _amount);
            }
        }
        IETHStrategy(_strategy).borrow(_assets, _amounts);
    }

    /// @notice Withdraw the funds from specified strategy.
    function redeem(
        address _strategy,
        uint256 _usdValue,
        uint256 _outputCode
    ) external payable {
        uint256 _totalValue = IETHStrategy(_strategy).estimatedTotalAssets();
        if (_usdValue > _totalValue) {
            _usdValue = _totalValue;
        }
        IETHStrategy(_strategy).repay(_usdValue, _totalValue, _outputCode);
    }

    function report(address[] memory _rewardTokens, uint256[] memory _claimAmounts) external {
        emit StrategyReported(msg.sender, 0, 0, 0, 0, _rewardTokens, _claimAmounts, 0);
    }
}