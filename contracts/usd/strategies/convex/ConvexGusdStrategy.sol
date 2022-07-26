// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Convex3CRVBaseStrategy.sol";

contract ConvexGusdStrategy is Convex3CRVBaseStrategy {
    function initialize(address _vault, address _harvester) public {
        super.__initialize(
            _vault,
            _harvester
        );
    }

    function getAnotherUSD() internal pure override returns(address) {
        return address(0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
    }
    
    function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
        return ICurveLiquidityPool(address(0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956));
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0x7A7bBf95C44b144979360C3300B54A7D34b44985));
    }

    function name() external pure override returns (string memory) {
        return "ConvexGusdStrategy";
    }
}