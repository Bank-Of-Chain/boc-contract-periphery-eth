// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IGUniPool is IERC20Upgradeable {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function lowerTick() external view returns (int24);

    function upperTick() external view returns (int24);

    function gelatoBalance0() external view returns (uint256);

    function gelatoBalance1() external view returns (uint256);

    function pool() external view returns (address);

    function mint(uint256 mintAmount, address receiver)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityMinted
        );

    function burn(uint256 burnAmount, address receiver)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );

    function getMintAmounts(uint256 amount0Max, uint256 amount1Max)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function getUnderlyingBalances() external view returns (uint256 amount0Current, uint256 amount1Current);

    function getUnderlyingBalancesAtPrice(uint160 sqrtRatioX96) external view returns (uint256 amount0Current, uint256 amount1Current);

    function getPositionID() external view returns (bytes32 positionID);
}
