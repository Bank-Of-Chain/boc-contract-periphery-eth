// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiDaiSushiStrategy is SushiKashiStakeBaseStrategy {

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
        return "SushiKashiDaiSushiStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 220;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0x05AD6d7dB640F4382184e2d82dD76b4581F8F8f4);
    }
}
