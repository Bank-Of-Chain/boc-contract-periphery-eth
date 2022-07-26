// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiUsdtSushiStrategy is SushiKashiStakeBaseStrategy {

    /**
     * @param _vault Our vault address
     */
    function initialize(
        address _vault,
        address _harvester
    ) public initializer {
        address underlying = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        super._initialize(
            _vault,
            _harvester,
            // DAI
            underlying);
    }

    function name() public pure override returns (string memory) {
        return "SushiKashiUsdtSushiStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 219;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0xF9a4e1e117818Fc98F9808f3DF4d7b72C0Df4160);
    }
}
