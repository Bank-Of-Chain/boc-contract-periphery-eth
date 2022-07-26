// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./YearnEarnBaseStrategy.sol";

contract YearnEarnDaiStrategy is YearnEarnBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester,
            0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01,
            0x6B175474E89094C44Da98b954EedeAC495271d0F
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "YearnEarnDaiStrategy";
    }
}
