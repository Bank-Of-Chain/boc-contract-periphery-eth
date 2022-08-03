// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Convex3CRVBaseStrategy.sol";

contract ConvexUsdpStrategy is Convex3CRVBaseStrategy {
    function initialize(address _vault, address _harvester) public {
        super.__initialize(
            _vault,
            _harvester
        );
    }

    function getAnotherUSD() internal pure override returns(address) {
        return address(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    }
    
    function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
        return ICurveLiquidityPool(address(0xc270b3B858c335B6BA5D5b10e2Da8a09976005ad));
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0x500E169c15961DE8798Edb52e0f88a8662d30EC5));
    }

    function name() external pure override returns (string memory) {
        return "ConvexUsdpStrategy";
    }
}
