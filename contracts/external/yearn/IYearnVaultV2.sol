// SPDX-License-Identifier: GPL-3.0
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

pragma solidity >=0.8.0 <0.9.0;

interface IYearnVaultV2 is IERC20Upgradeable {
    function decimals() external view returns (uint256);


    function deposit(uint256 amount) external returns (uint256);


    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(
        uint256 maxShares,
        uint256 slippageToleranceBps
    ) external returns (uint256);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function token() external view returns (address);
}
