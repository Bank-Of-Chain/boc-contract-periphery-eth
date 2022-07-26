// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IWstETH {
    function stEthPerToken() external view returns (uint256);
    function tokensPerStEth() external view returns (uint256);
    function decimals() external view returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
}
