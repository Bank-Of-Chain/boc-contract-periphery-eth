// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../../external/curve/ICurveLiquidityPoolPayable.sol";
import "./ConvexBaseStrategy.sol";
import "../../../external/weth/IWeth.sol";

contract ConvexSETHStrategy is ConvexBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address private constant sETH = 0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb;

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
    }

    function getCurvePool() internal pure override returns (ICurveLiquidityPoolPayable) {
        return ICurveLiquidityPoolPayable(address(0xc5424B857f758E906013F3555Dad202e4bdB4567));
    }

    function getConvexWants() internal pure override returns (address[] memory) {
        address[] memory _wants = new address[](2);
        _wants[0] = NATIVE_TOKEN;
        _wants[1] = sETH;
        return _wants;
    }

    function getConvexRewards() internal pure override returns (address[] memory) {
        address[] memory _rewards = new address[](2);
        _rewards[0] = CRV;
        _rewards[1] = CVX;
        return _rewards;
    }

    function getRewardPool() internal pure override returns (IConvexReward) {
        return IConvexReward(address(0x192469CadE297D6B21F418cFA8c366b63FFC9f9b));
    }

    function getLpToken() internal pure override returns (address) {
        return 0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c;
    }

    function getPid() internal pure override returns (uint256) {
        return 23;
    }

    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    function name() external pure override returns (string memory) {
        return "ConvexSETHStrategy";
    }

    function getWantsInfo() public view override returns (address[] memory _assets, uint256[] memory _ratios) {
        _assets = wants;
        _ratios = new uint256[](_assets.length);
        ICurveLiquidityPoolPayable curvePool = getCurvePool();
        for (uint256 i = 0; i < _assets.length; i++) {
            _ratios[i] = curvePool.balances(i);
        }
    }

    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory outputsInfo){
        outputsInfo = new OutputInfo[](3);
        OutputInfo memory info0 = outputsInfo[0];
        info0.outputCode = 0;
        info0.outputTokens = wants;

        OutputInfo memory info1 = outputsInfo[1];
        info1.outputCode = 1;
        info1.outputTokens = new address[](1);
        info1.outputTokens[0] = NATIVE_TOKEN;

        OutputInfo memory info2 = outputsInfo[2];
        info2.outputCode = 2;
        info2.outputTokens = new address[](1);
        info2.outputTokens[0] = sETH;
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
        ICurveLiquidityPoolPayable curvePool = getCurvePool();
        for (uint256 i = 0; i < wants.length; i++) {
            _amounts[i] = balanceOfToken(_tokens[i]) + (curvePool.balances(i) * lpAmount) / totalSupply;
        }
    }

    function sellWETH2Want() internal override {
        // Unwrap wEth to Eth
        IWeth(wETH).withdraw(balanceOfToken(wETH));
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal override {
        uint256 liquidity = curveAddLiquidity(_assets, _amounts);
        address lpToken = getLpToken();
        IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), 0);
        IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), liquidity);
        BOOSTER.deposit(getPid(), liquidity, true);
    }

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts) internal override returns (uint256) {
        uint256[2] memory depositArray;
        depositArray[0] = _amounts[0];
        depositArray[1] = _amounts[1];
        // only need to safeApprove sETH
        ICurveLiquidityPoolPayable curvePool = getCurvePool();
        address curvePoolAddress = address(curvePool);
        IERC20Upgradeable(_assets[1]).safeApprove(curvePoolAddress, 0);
        IERC20Upgradeable(_assets[1]).safeApprove(curvePoolAddress, _amounts[1]);
        if (_amounts[0] > 0) {
            return curvePool.add_liquidity{value: _amounts[0]}(depositArray, 0);
        }
        return curvePool.add_liquidity(depositArray, 0);
    }

    function curveRemoveLiquidity(uint256 liquidity,uint256 _outputCode) internal override {
        ICurveLiquidityPoolPayable pool = getCurvePool();
        if (_outputCode == 0){
            pool.remove_liquidity(liquidity, [uint256(0), uint256(0)]);
        } else if (_outputCode == 1){
            pool.remove_liquidity_one_coin(liquidity,0,0);
        } else if (_outputCode == 2){
            pool.remove_liquidity_one_coin(liquidity,1,0);
        }
        console.log('balanceOf NATIVE_TOKEN:', balanceOfToken(NATIVE_TOKEN));
        console.log('balanceOf sETH:', balanceOfToken(sETH));
    }
}
