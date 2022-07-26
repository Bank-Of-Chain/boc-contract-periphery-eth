// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import './IBalancerVault.sol';
interface IBalancerHelper {
    // solhint-disable-previous-line no-empty-blocks

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        IBalancerVault.JoinPoolRequest memory request
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        IBalancerVault.ExitPoolRequest memory request
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);
}
