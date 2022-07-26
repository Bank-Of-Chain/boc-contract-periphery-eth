// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DodoBaseStrategyV1.sol";

contract DodoUsdtUsdcStrategy is DodoBaseStrategyV1 {
    function initialize(address _vault, address _harvester) public initializer {
        address lpTokenPool = address(0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD);
        address stakingPool = address(0xaeD7384F03844Af886b830862FF0a7AFce0a632C);

        super._initialize(_vault, _harvester, lpTokenPool, stakingPool);
    }

    function name() public pure override returns (string memory) {
        return "DodoUsdtUsdcStrategy";
    }
}
