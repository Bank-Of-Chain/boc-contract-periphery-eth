// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @title ICurveAddressProvider interface
/// @author Enzyme Council <security@enzyme.finance>

interface IConvexDusdPoolToken {

    function balanceOf(address _account) external view returns(uint256);

}
