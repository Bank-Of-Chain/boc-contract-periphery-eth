// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./YearnEarnBaseStrategy.sol";

contract YearnEarnBusdStrategy is YearnEarnBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE,
            0x4Fabb145d64652a948d72533023f6E7A623C7C53
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "YearnEarnBusdStrategy";
    }
}
