// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DodoBaseStrategy.sol";

contract DodoDaiUsdtStrategy is DodoBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        address lpTokenPool = address(0x3058EF90929cb8180174D74C507176ccA6835D73);
        address stakingPool = address(0x1A4F8705E1C0428D020e1558A371b7E6134455A2);

        super._initialize(_vault, _harvester, lpTokenPool, stakingPool);
    }

    function name() public pure override returns (string memory) {
        return "DodoDaiUsdtStrategy";
    }
}
