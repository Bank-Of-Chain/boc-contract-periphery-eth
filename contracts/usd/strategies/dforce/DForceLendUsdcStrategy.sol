// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DForceLendBaseStrategy.sol";

contract DForceLendUsdcStrategy is DForceLendBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(
            _vault,
            _harvester
        );
    }

    function name() public pure override returns (string memory) {
        return "DForceLendUsdcStrategy";
    }

    function getIToken() internal pure override returns (address){
        return 0x2f956b2f801c6dad74E87E7f45c94f6283BF0f45;
    }

    function getDForceWants() internal pure override returns (address[] memory){
        address[] memory _wants = new address[](1);
        _wants[0] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        return _wants;
    }
}
