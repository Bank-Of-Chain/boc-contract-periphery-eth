pragma solidity >=0.8.0 <0.9.0;

interface IReadProxy {
    function target() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);
}