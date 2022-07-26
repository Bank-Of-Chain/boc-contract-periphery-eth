// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiDaiUniStrategy is SushiKashiStakeBaseStrategy {

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
        return "SushiKashiDaiUniStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 267;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0x651c7E8FA0aDd8c4531440650369533105113282);
    }
}
