// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./AuraBaseStrategy.sol";

contract AuraWstETHWETHStrategy is AuraBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    function initialize(address _vault) public {
        // bytes32 _poolKey = 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080;
        // uint256 _pId = 3;
        // address _poolLpToken = 0x32296969Ef14EB0c6d29669C550D4a0449130230;
        // address _rewardPool = 0xDCee1C640cC270121faF145f231fd8fF1d8d5CD4;
        address[] memory _wants = new address[](2);
        _wants[0] = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0; //wstETH
        _wants[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //wETH
        _initialize(_vault, _wants);

        address[] memory ldoSellPath = new address[](2);
        ldoSellPath[0] = LDO;
        ldoSellPath[1] = WETH;
        swapRewardRoutes[LDO] = ldoSellPath;

        isWantRatioIgnorable = true;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "AuraWstETHWETHStrategy";
    }

    function getPoolKey() internal pure override returns (bytes32) {
        return 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080;
    }

    function getPId() internal pure override returns (uint256) {
        return 3;
    }

    function getPoolLpToken() internal pure override returns (address) {
        return 0x32296969Ef14EB0c6d29669C550D4a0449130230;
    }

    function getRewardPool() internal pure override returns (address) {
        return 0xDCee1C640cC270121faF145f231fd8fF1d8d5CD4;
    }

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo()
        external
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        (, _ratios, ) = BALANCER_VAULT.getPoolTokens(getPoolKey());
    }

    /// @notice 3rd prototcol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 totalAssets;
        (address[] memory tokens, uint256[] memory balances, ) = BALANCER_VAULT.getPoolTokens(
            getPoolKey()
        );
        for (uint8 i = 0; i < tokens.length; i++) {
            totalAssets += queryTokenValueInETH(tokens[i], balances[i]);
        }
        return totalAssets;
    }

    function swapRewardsToWants() internal override {
        uint256 balanceOfBal = balanceOfToken(BAL);
        if (balanceOfBal < sellFloor[BAL]) return;
        if (balanceOfBal > 0) {
            IERC20Upgradeable(BAL).safeApprove(address(uniRouter2), 0);
            IERC20Upgradeable(BAL).safeApprove(address(uniRouter2), balanceOfBal);
            uniRouter2.swapExactTokensForTokens(
                balanceOfBal,
                0,
                swapRewardRoutes[BAL],
                address(this),
                block.timestamp
            );
        }

        uint256 balanceOfAura = balanceOfToken(AURA_TOKEN);
        if (balanceOfAura > 0) {
            IERC20Upgradeable(AURA_TOKEN).safeApprove(address(uniRouter2), 0);
            IERC20Upgradeable(AURA_TOKEN).safeApprove(address(uniRouter2), balanceOfAura);
            uniRouter2.swapExactTokensForTokens(
                balanceOfAura,
                0,
                swapRewardRoutes[AURA_TOKEN],
                address(this),
                block.timestamp
            );
        }

        uint256 balanceOfLdo = balanceOfToken(LDO);
        if (balanceOfLdo > 0) {
            IERC20Upgradeable(LDO).safeApprove(address(sushiRouter2), 0);
            IERC20Upgradeable(LDO).safeApprove(address(sushiRouter2), balanceOfAura);
            sushiRouter2.swapExactTokensForTokens(
                balanceOfLdo,
                0,
                swapRewardRoutes[LDO],
                address(this),
                block.timestamp
            );
        }
    }
}
