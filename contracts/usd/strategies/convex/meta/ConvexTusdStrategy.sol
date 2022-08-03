// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Convex3CRVBaseStrategy.sol";

contract ConvexTusdStrategy is Convex3CRVBaseStrategy {
    function initialize(address _vault, address _harvester) public {
        super.__initialize(
            _vault,
            _harvester
        );
    }

    function getAnotherUSD() internal pure override returns(address) {
        return address(0x0000000000085d4780B73119b644AE5ecd22b376);
    }
    
    function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
        return ICurveLiquidityPool(address(0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1));
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0x308b48F037AAa75406426dACFACA864ebd88eDbA));
    }

    function name() external pure override returns (string memory) {
        return "ConvexTusdStrategy";
    }
}
