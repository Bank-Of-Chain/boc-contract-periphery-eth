// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import '../eth/strategies/IETHStrategy.sol';
import "../external/stakewise/IMerkleDistributor.sol";

/// @title HarvestHelper 
/// @notice A util contract for the harvest action
contract HarvestHelper is AccessControlMixin {

    address internal constant RETH2 = 0x20BC832ca081b91433ff6c17f85701B6e92486c5;
    address internal constant SWISE = 0x48C3399719B582dD63eB5AADf12A40B4C3f52FA2;

    constructor(address _accessControlProxy) public {
        _initAccessControl(_accessControlProxy);
    }

    /// @notice Batch harvest from multi strategies
    /// @param _strategyAddrs The strategy list to harvest
    /// @return _totalAssets Th total asset of each strategy
    function batchHarvest(address[] memory _strategyAddrs) external isKeeper returns (uint256[] memory _totalAssets) {
        _totalAssets = new uint256[](_strategyAddrs.length);
        for (uint256 i = 0; i < _strategyAddrs.length; i++) {
            IETHStrategy(_strategyAddrs[i]).harvest();
            _totalAssets[i] = IETHStrategy(_strategyAddrs[i]).estimatedTotalAssets();
        }
    }

    /// @notice Claims reward from merkle distributor
    ///     Reverts if the inputs are invalid or the oracles are currently updating the merkle root.
    /// @param _index - the index of the user that is part of the merkle root.
    /// @param _account - the address of the user that is part of the merkle root.
    /// @param _tokens - list of the token addresses.
    /// @param _amounts - list of token amounts.
    /// @param _merkleProof - an array of hashes to verify whether the user is part of the merkle root.
    /// @return _rewardsTokens Th address list of reward token
    /// @return _claimAmounts Th amount list of reward token
    function stakeWiseMerkleDistributorClaim(
        uint256 _index, 
        address _account, 
        address[] calldata _tokens, 
        uint256[] calldata _amounts, 
        bytes32[] calldata _merkleProof
    ) public returns (
        address[] memory _rewardsTokens,
        uint256[] memory _claimAmounts
        ) 
    {
        _rewardsTokens = new address[](2);
        _rewardsTokens[0] = RETH2;
        _rewardsTokens[1] = SWISE;
        _claimAmounts = new uint256[](2);
        _claimAmounts[0] = IERC20Upgradeable(RETH2).balanceOf(address(_account));
        _claimAmounts[1] = IERC20Upgradeable(SWISE).balanceOf(address(_account));
        IMerkleDistributor(0xA3F21010e8b9a3930996C8849Df38f9Ca3647c20).claim(_index, _account, _tokens, _amounts, _merkleProof);
        _claimAmounts[0] = IERC20Upgradeable(RETH2).balanceOf(address(_account)) - _claimAmounts[0];
        _claimAmounts[1] = IERC20Upgradeable(SWISE).balanceOf(address(_account)) - _claimAmounts[1];
    }
}
