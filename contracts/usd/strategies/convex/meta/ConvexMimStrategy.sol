// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Convex3CRVBaseStrategy.sol";

contract ConvexMimStrategy is Convex3CRVBaseStrategy {
    function initialize(address _vault, address _harvester) public {
        super.__initialize(
            _vault,
            _harvester
        );
    }

    function getAnotherUSD() internal pure override returns(address) {
        return address(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    }
    
    function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
        return ICurveLiquidityPool(address(0x5a6A4D54456819380173272A5E8E9B9904BdF41B));
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771));
    }

    function name() external pure override returns (string memory) {
        return "ConvexMimStrategy";
    }
}
