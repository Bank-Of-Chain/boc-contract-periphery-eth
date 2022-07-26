// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @title ICurveLiquidityPool interface
/// @author Enzyme Council <security@enzyme.finance>
interface ICurveLiquidityPoolPayable {
    function totalSupply() external view returns (uint256);
    function get_virtual_price() external view returns (uint256);
    function balances(uint256) external view returns (uint256);
    function add_liquidity(uint256[2] calldata, uint256) external payable returns (uint256);
    function remove_liquidity(uint256, uint256[2] calldata) external ;
    function remove_liquidity_one_coin(uint256, int128, uint256) external;
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns(uint256);
}
