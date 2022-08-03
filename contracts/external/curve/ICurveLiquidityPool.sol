// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @title ICurveLiquidityPool interface
/// @author Enzyme Council <security@enzyme.finance>
interface ICurveLiquidityPool {
    function coins(uint256) external view returns (address);
    function balances(uint256) external view returns (uint256);
    function balances(int128) external view returns (uint256);

    function add_liquidity(uint256[2] calldata, uint256) external;
    function add_liquidity(uint256[2] calldata, uint256, bool) external returns(uint256);
    function add_liquidity(uint256[3] calldata, uint256) external;
    function add_liquidity(uint256[3] calldata, uint256, bool) external returns(uint256);
    function add_liquidity(uint256[4] calldata, uint256) external;

    function remove_liquidity(uint256, uint256[2] calldata) external ;
    function remove_liquidity(uint256, uint256[2] calldata, bool) external;
    function remove_liquidity(uint256, uint256[3] calldata) external ;
    function remove_liquidity(uint256, uint256[3] calldata, bool) external ;
    function remove_liquidity(uint256, uint256[4] calldata) external ;
    // function remove_liquidity_imbalance(uint256[3] memory amounts,uint256 max_burn_amount) external;

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;

    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256,
        bool
    ) external;

    function calc_withdraw_one_coin(uint256 _burn_amount,int128 i) external view returns(uint256);

    function exchange(
        int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
    ) external;

    function exchange_underlying(
        int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
    ) external;

    function get_virtual_price() external view returns (uint256);
}

