// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiDaiWethStrategy is SushiKashiStakeBaseStrategy {

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
        return "SushiKashiDaiWethStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 192;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0x5F92e4300024c447A103c161614E6918E794c764);
    }
}
