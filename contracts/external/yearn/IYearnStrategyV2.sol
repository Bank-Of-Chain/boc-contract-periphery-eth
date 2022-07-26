// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IYearnStrategyV2 {
    function tend() external;
    function harvest() external;
    function estimatedTotalAssets() external view returns (uint256);

    function claimableBalance() external view returns (uint256);
}
