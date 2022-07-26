// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../../external/curve/ICurveLiquidityPoolPayable.sol";
import "./ConvexBaseStrategy.sol";
import "../../../external/weth/IWeth.sol";

contract ConvexStETHStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    function initialize(address _vault) public {
        super._initialize(_vault);
        //set up sell reward path
        address[] memory rewardCRVPath = new address[](2);
        rewardCRVPath[0] = CRV;
        rewardCRVPath[1] = wETH;
        uniswapRewardRoutes[CRV] = rewardCRVPath;
        address[] memory rewardCVXPath = new address[](2);
        rewardCVXPath[0] = CVX;
        rewardCVXPath[1] = wETH;
        uniswapRewardRoutes[CVX] = rewardCVXPath;
        address[] memory rewardLDOPath = new address[](2);
        rewardLDOPath[0] = LDO;
        rewardLDOPath[1] = wETH;
        uniswapRewardRoutes[LDO] = rewardLDOPath;
    }

    function getCurvePool() internal pure override returns (ICurveLiquidityPoolPayable) {
        return ICurveLiquidityPoolPayable(address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022));
    }

    function getConvexWants() internal pure override returns (address[] memory) {
        address[] memory _wants = new address[](2);
        _wants[0] = NATIVE_TOKEN;
        _wants[1] = stETH;
        return _wants;
    }

    function getConvexRewards() internal pure override returns (address[] memory) {
        address[] memory _rewards = new address[](3);
        _rewards[0] = CRV;
        _rewards[1] = CVX;
        _rewards[2] = LDO;
        return _rewards;
    }

    function getRewardPool() internal pure override returns (IConvexReward) {
        return IConvexReward(address(0x0A760466E1B4621579a82a39CB56Dda2F4E70f03));
    }

    function getLpToken() internal pure override returns (address) {
        return 0x06325440D014e39736583c165C2963BA99fAf14E;
    }

    function getPid() internal pure override returns (uint256) {
        return 25;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "ConvexStETHStrategy";
    }

    function getWantsInfo() public view override returns (address[] memory _assets, uint256[] memory _ratios) {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = getCurvePool().balances(i);
        }
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
        uint256 totalSupply = IERC20Upgradeable(getLpToken()).totalSupply();
        for (uint256 i = 0; i < wants.length; i++) {
            _amounts[i] = balanceOfToken(_tokens[i]) + (getCurvePool().balances(i) * lpAmount) / totalSupply;
        }
    }

    function sellWETH2Want() internal override {
        // Unwrap wEth to Eth
        IWeth(wETH).withdraw(balanceOfToken(wETH));
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal override {
        bool isDeposit = false;
        for (uint256 i = 0; i < _amounts.length; i++) {
            if (_amounts[i] > 0) {
                isDeposit = true;
                break;
            }
        }
        if (isDeposit) {
            // https://etherscan.io/tx/0x05ccc4242d3d5192a5ff30195cd1aa0ddb434b50fa88ffc55281ccc0bdb94c13
            uint256 liquidity = curveAddLiquidity(_assets, _amounts);
            address lpToken = getLpToken();
            IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), 0);
            IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), liquidity);
            // deposit into convex booster and stake at reward pool automatically
            // https://etherscan.io/tx/0xfdc8f347440dc9adeaa0b59201c653fd09c2cfffb97b35df08de7af5691b02ec
            BOOSTER.deposit(getPid(), liquidity, true);
        }
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts) internal override returns (uint256) {
        uint256[2] memory depositArray;
        depositArray[0] = _amounts[0];
        depositArray[1] = _amounts[1];
        // only need to safeApprove stETH
        IERC20Upgradeable(_assets[1]).safeApprove(address(getCurvePool()), 0);
        IERC20Upgradeable(_assets[1]).safeApprove(address(getCurvePool()), _amounts[1]);
        if (_amounts[0] > 0) {
            return getCurvePool().add_liquidity{value: _amounts[0]}(depositArray, 0);
        }
        return getCurvePool().add_liquidity(depositArray, 0);
    }

    function curveRemoveLiquidity(uint256 liquidity) internal override {
        getCurvePool().remove_liquidity(liquidity, [uint256(0), uint256(0)]);
    }
}
