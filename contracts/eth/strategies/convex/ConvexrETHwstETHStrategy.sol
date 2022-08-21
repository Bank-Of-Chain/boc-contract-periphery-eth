// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../../external/curve/ICurveLiquidityPoolPayable.sol";
import "../../../external/weth/IWeth.sol";
import "./ConvexBaseStrategy.sol";

contract ConvexrETHwstETHStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address private constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    function initialize(address _vault, string memory _name) external initializer {
        super._initialize(_vault, _name);
        //set up sell reward path
        address[] memory _rewardCRVPath = new address[](2);
        _rewardCRVPath[0] = CRV;
        _rewardCRVPath[1] = wETH;
        uniswapRewardRoutes[CRV] = _rewardCRVPath;
        address[] memory _rewardCVXPath = new address[](2);
        _rewardCVXPath[0] = CVX;
        _rewardCVXPath[1] = wETH;
        uniswapRewardRoutes[CVX] = _rewardCVXPath;
    }

    function getConvexWants() internal pure override returns (address[] memory) {
        address[] memory _wants = new address[](2);
        // the order get from CURVE_POOL's coin()
        _wants[0] = rETH;
        _wants[1] = wstETH;
        return _wants;
    }

    function getConvexRewards() internal pure override returns (address[] memory) {
        address[] memory _rewards = new address[](2);
        _rewards[0] = CRV;
        _rewards[1] = CVX;
        return _rewards;
    }

    function getRewardPool() internal pure override returns (IConvexReward) {
        return IConvexReward(address(0x5c463069b99AfC9333F4dC2203a9f0c6C7658cCc));
    }

    function getCurvePool() internal pure override returns (ICurveLiquidityPoolPayable) {
        return ICurveLiquidityPoolPayable(address(0x447Ddd4960d9fdBF6af9a790560d0AF76795CB08));
    }

    function getLpToken() internal pure override returns (address) {
        return 0x447Ddd4960d9fdBF6af9a790560d0AF76795CB08;
    }

    function getPid() internal pure override returns (uint256) {
        return 73;
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

        _ratios[0] = getCurvePool().balances(0);
        _ratios[1] = getCurvePool().balances(1);
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](3);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;

        OutputInfo memory _info1 = _outputsInfo[1];
        _info1.outputCode = 1;
        _info1.outputTokens = new address[](1);
        _info1.outputTokens[0] = rETH;

        OutputInfo memory _info2 = _outputsInfo[2];
        _info2.outputCode = 2;
        _info2.outputTokens = new address[](1);
        _info2.outputTokens[0] = wstETH;
    }

    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](_tokens.length);
        // curve LP token amount = convex LP token amount
        uint256 _lpAmount = balanceOfLpToken();
        // curve LP total supply
        uint256 _totalSupply = IERC20Upgradeable(getLpToken()).totalSupply();
        _amounts[0] =
            balanceOfToken(_tokens[0]) +
            (getCurvePool().balances(0) * _lpAmount) /
            _totalSupply;
        _amounts[1] =
            balanceOfToken(_tokens[1]) +
            (getCurvePool().balances(1) * _lpAmount) /
            _totalSupply;
    }

    function sellWETH2Want() internal override {
        IWeth(wETH).withdraw(balanceOfToken(wETH));
        convertETH2wstETH();
    }

    function convertETH2wstETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool sent, ) = payable(wstETH).call{value: balance}("");
            require(sent, "Failed to convert");
        }
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        bool _isDeposit = false;
        convertETH2wstETH();
        if (balanceOfToken(wstETH) > 0) {
            _isDeposit = true;
        } else {
            for (uint256 i = 0; i < _amounts.length; i++) {
                if (_amounts[i] > 0) {
                    _isDeposit = true;
                    break;
                }
            }
        }

        if (_isDeposit) {
            _assets[1] = wstETH;
            _amounts[1] = balanceOfToken(wstETH);
            // https://etherscan.io/tx/0x05ccc4242d3d5192a5ff30195cd1aa0ddb434b50fa88ffc55281ccc0bdb94c13
            uint256 _liquidity = curveAddLiquidity(_assets, _amounts);
            address _lpToken = getLpToken();
            IERC20Upgradeable(_lpToken).safeApprove(address(BOOSTER), 0);
            IERC20Upgradeable(_lpToken).safeApprove(address(BOOSTER), _liquidity);
            // deposit into convex booster and stake at reward pool automatically
            // https://etherscan.io/tx/0xfdc8f347440dc9adeaa0b59201c653fd09c2cfffb97b35df08de7af5691b02ec
            BOOSTER.deposit(getPid(), _liquidity, true);
        }
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
        returns (uint256)
    {
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20Upgradeable(_assets[i]).safeApprove(address(getCurvePool()), 0);
                IERC20Upgradeable(_assets[i]).safeApprove(address(getCurvePool()), _amounts[i]);
            }
        }
        return getCurvePool().add_liquidity([_amounts[0], _amounts[1]], 0);
    }

    function curveRemoveLiquidity(uint256 _liquidity, uint256 _outputCode) internal override {
        ICurveLiquidityPoolPayable _pool = getCurvePool();
        if (_outputCode == 1) {
            _pool.remove_liquidity_one_coin(_liquidity, 0, 0);
        } else if (_outputCode == 2) {
            _pool.remove_liquidity_one_coin(_liquidity, 1, 0);
        } else {
            _pool.remove_liquidity(_liquidity, [uint256(0), uint256(0)]);
        }
    }
}
