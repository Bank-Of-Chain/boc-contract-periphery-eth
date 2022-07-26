// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Convex3CRVBaseStrategy.sol";

contract ConvexBusdV2Strategy is Convex3CRVBaseStrategy {
    function initialize(address _vault, address _harvester) public {
        super.__initialize(
            _vault,
            _harvester
        );
    }

    function getAnotherUSD() internal pure override returns(address) {
        return address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    }
    
    function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
        return ICurveLiquidityPool(address(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a));
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0xbD223812d360C9587921292D0644D18aDb6a2ad0));
    }

    function name() external pure override returns (string memory) {
        return "ConvexBusdV2Strategy";
    }
}
