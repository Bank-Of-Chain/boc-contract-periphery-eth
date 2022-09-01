// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Mock3rdEthPool {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    receive() external payable {}

    function deposit(address[] memory _assets, uint256[] memory _amounts)
        payable
        external {
            IERC20Upgradeable(stETH).safeTransferFrom(msg.sender, address(this), _amounts[1]);
        }

    function withdraw()
        external
        returns (address[] memory _assets, uint256[] memory _amounts) {
            _assets = new address[](2);
            _assets[0] = address(0);
            _assets[1] = stETH;
            _amounts = new uint256[](2);
            _amounts[0] = address(this).balance;
            _amounts[1] = IERC20Upgradeable(stETH).balanceOf(address(this));
            payable(msg.sender).transfer(_amounts[0]);
            IERC20Upgradeable(stETH).safeTransfer(msg.sender, _amounts[1]);
        }

    function pricePerShare() external view returns (uint256) {
        return 1e18;
    }

    function getPendingRewards()
        external
        view
        returns (
            address[] memory _rewardsTokens,
            uint256[] memory _pendingAmounts
        ) {}

    function claim() external returns (uint256[] memory _claimAmounts) {
    }

}
