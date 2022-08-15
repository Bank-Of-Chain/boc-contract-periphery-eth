// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../external/curve/ICurveLiquidityPool.sol";

import "./ConvexBaseStrategy.sol";

contract ConvexSaaveStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address private constant CVX = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address private constant STKAAVE = address(0x4da27a545c0c5B758a6BA100e3a049001de870f5);

    function initialize(
        address _vault,
        address _harvester,
        string memory _name
    ) public {
        address[] memory _wants = new address[](2);
        // the oder is same with underlying coins
        // DAI
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        // sUSD
        _wants[1] = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
        super._initialize(
            _vault,
            _harvester,
            _name,
            _wants,
            0xEB16Ae0052ed37f479f7fe63849198Df1765a733,
            0xF86AE6790654b70727dbE58BF1a863B270317fD0
        );
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = pool.balances(i);
        }
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory outputsInfo)
    {
        address[] memory _wants = wants;
        outputsInfo = new OutputInfo[](3);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = _wants;

        OutputInfo memory info1 = outputsInfo[1];
        info1.outputCode = 1;
        info1.outputTokens = new address[](1);
        info1.outputTokens[0] = _wants[0];

        OutputInfo memory info2 = outputsInfo[2];
        info2.outputCode = 2;
        info2.outputTokens = new address[](1);
        info2.outputTokens[0] = _wants[1];
    }

    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool isUsd,
            uint256 usdValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](_tokens.length);
        // curve LP token amount = convex LP token amount
        uint256 lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 totalSupply = IERC20Upgradeable(lpToken).totalSupply();
        // calc balances
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 depositedTokenAmount = (pool.balances(i) * lpAmount) / totalSupply;
            _amounts[i] = balanceOfToken(_tokens[i]) + depositedTokenAmount;
        }
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address[] memory _assets = wants;
        uint256 thirdPoolAssets;
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 thirdPoolAssetBalance = pool.balances(i);
            thirdPoolAssets += queryTokenValue(_assets[i], thirdPoolAssetBalance);
        }
        return thirdPoolAssets;
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        address _curvePool = curvePool;
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).safeApprove(_curvePool, 0);
                IERC20Upgradeable(_assets[i]).safeApprove(_curvePool, _amounts[i]);
            }
        }
        return ICurveLiquidityPool(_curvePool).add_liquidity([_amounts[0], _amounts[1]], 0, true);
    }

    function curveRemoveLiquidity(uint256 liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool pool = ICurveLiquidityPool(curvePool);
        if (_outputCode == 1) {
            pool.remove_liquidity_one_coin(liquidity, 0, 0, true);
        } else if (_outputCode == 2) {
            pool.remove_liquidity_one_coin(liquidity, 1, 0, true);
        } else {
            pool.remove_liquidity(liquidity, [uint256(0), uint256(0)], true);
        }
    }

    function claimRewards()
        internal
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        IConvexReward(rewardPool).getReward();
        _rewardTokens = new address[](3);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        _rewardTokens[2] = STKAAVE;
        _claimAmounts = new uint256[](3);
        _claimAmounts[0] = balanceOfToken(CRV);
        _claimAmounts[1] = balanceOfToken(CVX);
        _claimAmounts[2] = balanceOfToken(STKAAVE);
    }
}
