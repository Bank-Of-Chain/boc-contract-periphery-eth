// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "../oracle/PriceOracle.sol";
import "../strategies/IETHStrategy.sol";
import "hardhat/console.sol";

contract MockVault is AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public priceProvider;
    
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _accessControlProxy, address _valueInterpreter) {
        _initAccessControl(_accessControlProxy);
        priceProvider = _valueInterpreter;
    }

    function treasury() view external returns(address){
        return address(this);
    }

    function burn(uint256 _amount) external {}

    function lend(
        address _strategy,
        address[] memory _assets,
        uint256[] memory _amounts
    ) external {
        for (uint8 i = 0; i < _assets.length; i++) {
            address token = _assets[i];
            uint256 amount = _amounts[i];
            if (token == ETH) {
                payable(address(_strategy)).transfer(amount);
            } else {
                IERC20Upgradeable item = IERC20Upgradeable(token);
                console.log("balance:%d,amount:%d", item.balanceOf(address(this)), amount);
                item.safeTransfer(_strategy, amount);
            }
        }
        IETHStrategy(_strategy).borrow(_assets, _amounts);
    }

    /// @notice Withdraw the funds from specified strategy.
    function redeem(address _strategy, uint256 _usdValue) external payable {
        uint256 totalValue = IETHStrategy(_strategy).estimatedTotalAssets();
        if (_usdValue > totalValue) {
            _usdValue = totalValue;
        }
        IETHStrategy(_strategy).repay(_usdValue, totalValue);
    }

    function report() external {}

    receive() external payable {}
}
