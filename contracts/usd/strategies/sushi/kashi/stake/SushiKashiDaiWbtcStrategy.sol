// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiDaiWbtcStrategy is SushiKashiStakeBaseStrategy {

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
        return "SushiKashiDaiWbtcStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 194;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0x418BC3ff0Ba33AD64931160A91C92fA26b35aCB0);
    }
}
