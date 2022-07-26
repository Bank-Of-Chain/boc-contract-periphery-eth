// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DForceLendBaseStrategy.sol";

contract DForceLendUsdtStrategy is DForceLendBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester
        );
    }

    function name() public pure override returns (string memory) {
        return "DForceLendUsdtStrategy";
    }

    function getIToken() internal pure override returns (address){
        return 0x1180c114f7fAdCB6957670432a3Cf8Ef08Ab5354;
    }

    function getDForceWants() internal pure override returns (address[] memory){
        address[] memory _wants = new address[](1);
        _wants[0] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        return _wants;
    }
}
