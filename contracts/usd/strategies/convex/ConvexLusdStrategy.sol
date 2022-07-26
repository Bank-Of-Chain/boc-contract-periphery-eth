// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Convex3CRVBaseStrategy.sol";

contract ConvexLusdStrategy is Convex3CRVBaseStrategy {
    function initialize(address _vault, address _harvester) public {
        super.__initialize(
            _vault,
            _harvester
        );
    }

    function getAnotherUSD() internal pure override returns(address) {
        return address(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
    }
    
    function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
        return ICurveLiquidityPool(address(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA));
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0x2ad92A7aE036a038ff02B96c88de868ddf3f8190));
    }

    function name() external pure override returns (string memory) {
        return "ConvexLusdStrategy";
    }
}
