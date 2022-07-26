// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiUsdtLinkStrategy is SushiKashiStakeBaseStrategy {

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
        return "SushiKashiUsdtLinkStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 196;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0xC84Fb1F76cbdd3b3491E81FE3ff811248d0407e9);
    }
}
