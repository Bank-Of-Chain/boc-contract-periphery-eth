// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./SushiKashiStakeBaseStrategy.sol";

contract SushiKashiUsdcCompStrategy is SushiKashiStakeBaseStrategy {

    /**
     * @param _vault Our vault address
     */
    function initialize(
        address _vault,
        address _harvester
    ) public initializer {
        address underlying = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        super._initialize(
            _vault,
            _harvester,
            // DAI
            underlying);
    }

    function name() public pure override returns (string memory) {
        return "SushiKashiUsdcCompStrategy";
    }

    function getPoolId() override public pure returns (uint16){
        return 261;
    }

    function getKashiPair() override public pure returns (IKashiPair){
        return IKashiPair(0x0d2606158fA76b38C5d58dB94B223C3BdCBbf57C);
    }
}
