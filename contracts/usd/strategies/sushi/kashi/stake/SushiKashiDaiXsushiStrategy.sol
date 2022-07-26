// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiDaiXsushiStrategy is SushiKashiStakeBaseStrategy {

    /**
     * @param _vault Our vault address
     */
    function initialize(
        address _vault,
        address _harvester
    ) public initializer {
        address underlying = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        super._initialize(
            _vault,
            _harvester,
            // DAI
            underlying);
    }

    function name() public pure override returns (string memory) {
        return "SushiKashiDaiXsushiStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 246;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0x77F3A4Fa35BaC0EA6CfaC69037Ac4d3a757240A1);
    }
}
