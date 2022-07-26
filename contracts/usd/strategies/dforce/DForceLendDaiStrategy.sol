// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DForceLendBaseStrategy.sol";

contract DForceLendDaiStrategy is DForceLendBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester
        );
    }

    function name() public pure override returns (string memory) {
        return "DForceLendDaiStrategy";
    }

    function getIToken() internal pure override returns (address){
        return 0x298f243aD592b6027d4717fBe9DeCda668E3c3A8;
    }

    function getDForceWants() internal pure override returns (address[] memory){
        address[] memory _wants = new address[](1);
        _wants[0] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        return _wants;
    }

}
