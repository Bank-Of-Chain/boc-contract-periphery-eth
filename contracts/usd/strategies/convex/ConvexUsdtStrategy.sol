// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./ConvexBaseStrategy.sol";
import "../../../external/compound/ICToken.sol";
import "../../../external/curve/ICurveLiquidityPool.sol";

contract ConvexUsdtStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant cDAI = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    address private constant cUSDC = address(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    address private constant curvePool = address(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);

    function initialize(address _vault, address _harvester) public initializer {
        address[] memory _wants = new address[](3);
        _wants[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        _wants[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        _wants[2] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        super._initialize(_vault, _harvester, _wants);
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function getRewardPool() internal pure override returns (IConvexReward) {
        return IConvexReward(address(0x8B55351ea358e5Eda371575B031ee24F462d503e));
    }

    function name() public pure override returns (string memory) {
        return "ConvexUsdtStrategy";
    }

    function getWantsInfo()
        public
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        _ratios[0] = ((ICToken(cDAI).balanceOf(curvePool) * (ICToken(cDAI).totalBorrows())) /
            ICToken(cDAI).totalSupply());
        _ratios[1] = ((ICToken(cUSDC).balanceOf(curvePool) * (ICToken(cDAI).totalBorrows())) /
            ICToken(cDAI).totalSupply());
        _ratios[2] = IERC20Upgradeable(_assets[2]).balanceOf(curvePool);
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory outputsInfo)
    {
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = wants;

        // not support remove_liquidity_one_coin
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        uint256 amount = _amounts[2];
        IERC20Upgradeable(_assets[0]).safeApprove(cDAI, 0);
        IERC20Upgradeable(_assets[0]).safeApprove(cDAI, _amounts[0]);
        ICToken(cDAI).mint(_amounts[0]);
        uint256 cDAIBalance = balanceOfToken(cDAI);
        IERC20Upgradeable(_assets[1]).safeApprove(cUSDC, 0);
        IERC20Upgradeable(_assets[1]).safeApprove(cUSDC, _amounts[1]);
        ICToken(cUSDC).mint(_amounts[1]);
        uint256 cUSDCBalance = balanceOfToken(cUSDC);

        IERC20Upgradeable(cDAI).safeApprove(curvePool, 0);
        IERC20Upgradeable(cDAI).safeApprove(curvePool, cDAIBalance);
        IERC20Upgradeable(cUSDC).safeApprove(curvePool, 0);
        IERC20Upgradeable(cUSDC).safeApprove(curvePool, cUSDCBalance);
        IERC20Upgradeable(_assets[2]).safeApprove(curvePool, 0);
        IERC20Upgradeable(_assets[2]).safeApprove(curvePool, amount);
        ICurveLiquidityPool(curvePool).add_liquidity([cDAIBalance, cUSDCBalance, amount], 0);
        return balanceOfToken(lpToken);
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
        isUsd = true;
        usdValue =
            (ICurveLiquidityPool(curvePool).get_virtual_price() * balanceOfLpToken()) /
            decimalUnitOfToken(lpToken);
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        return
            (ICurveLiquidityPool(curvePool).get_virtual_price() *
                IERC20Upgradeable(lpToken).totalSupply()) / decimalUnitOfToken(lpToken);
    }

    function curveRemoveLiquidity(uint256 removeLiquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPool(curvePool).remove_liquidity(
            removeLiquidity,
            [uint256(0), uint256(0), uint256(0)]
        );
        uint256 daiBalance = balanceOfToken(cDAI);
        console.log("daiBalance:%d", daiBalance);
        if (daiBalance > 0) {
            ICToken(cDAI).redeem(daiBalance);
        }
        uint256 usdcBalance = balanceOfToken(cUSDC);
        console.log("usdcBalance:%d", usdcBalance);
        if (usdcBalance > 0) {
            ICToken(cUSDC).redeem(usdcBalance);
        }
    }
}
