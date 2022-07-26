// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./YearnEarnBaseStrategy.sol";

contract YearnEarnTusdStrategy is YearnEarnBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            0x73a052500105205d34Daf004eAb301916DA8190f,
            0x0000000000085d4780B73119b644AE5ecd22b376
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "YearnEarnTusdStrategy";
    }
}
