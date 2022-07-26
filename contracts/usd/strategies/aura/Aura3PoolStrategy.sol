// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./AuraBaseStrategy.sol";

contract Aura3PoolStrategy is AuraBaseStrategy {
    function initialize(address _vault, address _harvester) public {
        address[] memory _wants = new address[](3);
        _wants[0] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //DAI
        _wants[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //USDC
        _wants[2] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //USDT
        super._initialize(_vault, _harvester, _wants);

        isWantRatioIgnorable = true;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "Aura3PoolStrategy";
    }

    function getPoolKey() internal pure override returns (bytes32) {
        return 0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000063;
    }

    function getPId() internal pure override returns (uint256) {
        return 0;
    }

    function getPoolLpToken() internal pure override returns (address) {
        return 0x06Df3b2bbB68adc8B0e302443692037ED9f91b42;
    }

    function getRewardPool() internal pure override returns (address) {
        return 0x08b8a86B9498AC249bF4B86e14C5d4187085a239;
    }

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo()
        external
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        (_assets, _ratios, ) = BALANCER_VAULT.getPoolTokens(getPoolKey());
    }

    /// @notice 3rd prototcol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 totalAssets;
        (address[] memory tokens, uint256[] memory balances, ) = BALANCER_VAULT.getPoolTokens(
            getPoolKey()
        );
        for (uint8 i = 0; i < tokens.length; i++) {
            totalAssets += queryTokenValue(tokens[i], balances[i]);
        }
        return totalAssets;
    }
}
