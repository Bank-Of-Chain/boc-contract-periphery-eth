// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ConvexYTokenBaseStrategy.sol";

contract ConvexYStrategy is ConvexYTokenBaseStrategy {

    function initialize(address _vault, address _harvester) public {
        super.__initialize(
            _vault,
            _harvester
        );
    }

    function name() external pure override returns (string memory) {
        return "ConvexYStrategy";
    }

    function getAnotherUSD() internal pure override returns(address) {
        return address(0x0000000000085d4780B73119b644AE5ecd22b376);
    }
    
    function getCurvePool() internal pure override returns(ICurveLiquidityPool) {
        return ICurveLiquidityPool(address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51));
    }

    function getRewardPool() internal pure override returns(IConvexReward) {
        return IConvexReward(address(0xd802a8351A76ED5eCd89A7502Ca615F2225A585d));
    }

    function getYTokens() internal pure override returns (IYearnVault[] memory) {
        IYearnVault[] memory yTokens = new IYearnVault[](4);
        yTokens[0] = IYearnVault(address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01));
        yTokens[1] = IYearnVault(address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e));
        yTokens[2] = IYearnVault(address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D));
        yTokens[3] = IYearnVault(address(0x73a052500105205d34Daf004eAb301916DA8190f));
        return yTokens;
    }
}
