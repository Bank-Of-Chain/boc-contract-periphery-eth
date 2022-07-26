// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./StargateBaseStrategy.sol";

contract StargateUsdtStrategy is StargateBaseStrategy {
    function initialize(address _vault, address _harvester) public initializer {
        super._initialize(_vault, _harvester);
    }

    function name() public pure override returns (string memory) {
        return "StargateUsdtStrategy";
    }

    function getStakePoolInfoId() internal pure override returns (uint256) {
        return 1;
    }

    function getLpToken() internal pure override returns (address){
        return 0x38EA452219524Bb87e18dE1C24D3bB59510BD783;
    }

    function getRouter() internal pure override returns (address){
        return 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    }

    function getPoolId() internal pure override returns (uint256){
        return 2;
    }

    function getStargateWants() internal pure override returns (address[] memory){
        address[] memory _wants = new address[](1);
        _wants[0] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        return _wants;
    }
}
