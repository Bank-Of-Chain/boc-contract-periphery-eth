pragma solidity >=0.8.0 <0.9.0;

interface ICurveLiquidityFarmingPool {

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external payable returns (uint256);
}