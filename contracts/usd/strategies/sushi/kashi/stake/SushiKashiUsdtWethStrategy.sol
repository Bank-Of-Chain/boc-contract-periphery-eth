// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiUsdtWethStrategy is SushiKashiStakeBaseStrategy {
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
            underlying
        );
    }

    function name() public pure override returns (string memory) {
        return "SushiKashiUsdtWethStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 190;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0xfF7D29c7277D8A8850c473f0b71d7e5c4Af45A50);
    }
}
