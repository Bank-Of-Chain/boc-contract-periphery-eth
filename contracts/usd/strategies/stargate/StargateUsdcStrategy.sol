// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StargateBaseStrategy.sol";

contract StargateUsdcStrategy is StargateBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(_vault, _harvester);
    }

    function name() public pure override returns (string memory) {
        return "StargateUsdcStrategy";
    }

    function getStakePoolInfoId() internal pure override returns (uint256) {
        return 0;
    }

    function getLpToken() internal pure override returns (address){
        return 0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56;
    }

    function getRouter() internal pure override returns (address){
        return 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    }

    function getPoolId() internal pure override returns (uint256){
        return 1;
    }

    function getStargateWants() internal pure override returns (address[] memory){
        address[] memory _wants = new address[](1);
        _wants[0] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        return _wants;
    }

}
