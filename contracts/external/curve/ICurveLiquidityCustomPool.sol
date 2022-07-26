pragma solidity ^0.8.0;

interface ICurveLiquidityCustomPool {
    function balances(int128) external view returns (uint256);
    function balances(uint256) external view returns (uint256);
}