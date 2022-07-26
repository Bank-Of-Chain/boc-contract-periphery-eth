// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiUsdtXsushiStrategy is SushiKashiStakeBaseStrategy {

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
            // USDT
            underlying);
    }

    function name() public pure override returns (string memory) {
        return "SushiKashiUsdtXsushiStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 249;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0x17Fb5f39C55903DE60E63543067031cE2B2659EE);
    }
}
