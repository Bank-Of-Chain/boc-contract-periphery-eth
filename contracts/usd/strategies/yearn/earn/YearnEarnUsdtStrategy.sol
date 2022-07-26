// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./YearnEarnBaseStrategy.sol";

contract YearnEarnUsdtStrategy is YearnEarnBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            0x83f798e925BcD4017Eb265844FDDAbb448f1707D,
            0xdAC17F958D2ee523a2206206994597C13D831ec7
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "YearnEarnUsdtStrategy";
    }
}
