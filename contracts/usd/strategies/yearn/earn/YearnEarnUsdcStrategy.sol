// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./YearnEarnBaseStrategy.sol";

contract YearnEarnUsdcStrategy is YearnEarnBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            0xd6aD7a6750A7593E092a9B218d66C0A814a3436e,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "YearnEarnUsdcStrategy";
    }
}
