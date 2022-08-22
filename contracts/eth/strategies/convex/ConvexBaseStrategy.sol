// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../ETHBaseClaimableStrategy.sol";
import "../../../external/convex/IConvexReward.sol";
import "../../../external/convex/IConvex.sol";
import "../../enums/ProtocolEnum.sol";
import "../../../external/uniswap/IUniswapV2Router2.sol";
import "../../../external/curve/ICurveLiquidityPoolPayable.sol";

abstract contract ConvexBaseStrategy is ETHBaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    mapping(address => address[]) public uniswapRewardRoutes;
    mapping(address => uint256) public sellFloor;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    IConvex internal constant BOOSTER = IConvex(address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31));
    IUniswapV2Router2 public constant ROUTER2 = IUniswapV2Router2(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    function _initialize(address _vault,string memory _name) internal {
        super._initialize(_vault, uint16(ProtocolEnum.Convex), _name,getConvexWants());
        isWantRatioIgnorable = true;
        sellFloor[CRV] = 1e16;
    }

    function setSellFloor(address _token, uint256 _floor) public isVaultManager {
        sellFloor[_token] = _floor;
    }

    function setRewardSwapPath(address _token, address[] memory _uniswapRouteToToken) public isVaultManager {
        require(_token == _uniswapRouteToToken[_uniswapRouteToToken.length - 1]);
        uniswapRewardRoutes[_token] = _uniswapRouteToToken;
    }

    function getRewardPool() internal pure virtual returns (IConvexReward);

    function getPid() internal pure virtual returns (uint256);

    function getLpToken() internal pure virtual returns (address);

    function getConvexWants() internal pure virtual returns (address[] memory);

    function getConvexRewards() internal pure virtual returns (address[] memory);

    function getCurvePool() internal pure virtual returns (ICurveLiquidityPoolPayable);

    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts) internal virtual returns (uint256);

    function curveRemoveLiquidity(uint256 _liquidity,uint256 _outputCode) internal virtual;

    function sellWETH2Want() internal virtual;

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares,uint256 _outputCode) internal override {
        uint256 _lpAmount = (balanceOfLpToken() * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            // https://etherscan.io/tx/0x9afc916be07738a7a4556d555c59e775d17ddc32d6eb48cdab83e006cd613394
            getRewardPool().withdrawAndUnwrap(_lpAmount, false);
            curveRemoveLiquidity(_lpAmount,_outputCode);
        }
    }

    // https://etherscan.io/tx/0x0d6595b02f7c54ccb669cd72383b0dd54c0a00e3195f109843617889a967db3a
    function claimRewards()
        internal
        virtual
        override
        returns (
            bool _isWorth,
            address[] memory _assets,
            uint256[] memory _amounts
        )
    {
        uint256 _rewardCRVAmount = getRewardPool().earned(address(this));
        if (_rewardCRVAmount > sellFloor[CRV]) {
            getRewardPool().getReward();
            _assets = getConvexRewards();
            _amounts = new uint256[](_assets.length);
            for (uint256 i = 0; i < _assets.length; i++) {
                _amounts[i] = balanceOfToken(_assets[i]);
            }
            _isWorth = true;
        }
    }

    function swapRewardsToWants() internal virtual override returns(address[] memory _wantTokens,uint256[] memory _wantAmounts){
        uint256 _wethBalanceInit = balanceOfToken(wETH);
        uint256 _wethBalanceLast = _wethBalanceInit;
        uint256 _wethBalanceCur;

        address[] memory _rewardTokens = getConvexRewards();
        _wantTokens = new address[](_rewardTokens.length);
        _wantAmounts = new uint256[](_rewardTokens.length);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            uint256 _rewardAmount = balanceOfToken(_rewardTokens[i]);
            _wantTokens[i] = wETH;
            if (_rewardAmount > 0) {
                IERC20Upgradeable(_rewardTokens[i]).safeApprove(address(ROUTER2), 0);
                IERC20Upgradeable(_rewardTokens[i]).safeApprove(address(ROUTER2), _rewardAmount);
                // sell to one coin then reinvest
                ROUTER2.swapExactTokensForTokens(_rewardAmount, 0, uniswapRewardRoutes[_rewardTokens[i]], address(this), block.timestamp);
            }
            _wethBalanceCur = balanceOfToken(wETH);
            _wantAmounts[i] = _wethBalanceCur - _wethBalanceLast;
            _wethBalanceLast = _wethBalanceCur;
        }
        sellWETH2Want();
    }

    function balanceOfLpToken() internal view returns (uint256) {
        return getRewardPool().balanceOf(address(this));
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        uint256 _thirdPoolAssets = 0;
        for (uint256 i = 0; i < wants.length; i++) {
            _thirdPoolAssets = _thirdPoolAssets + queryTokenValueInETH(wants[i], getCurvePool().balances(i));
        }
        return _thirdPoolAssets;
    }
}
