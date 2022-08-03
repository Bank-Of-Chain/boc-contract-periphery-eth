// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";

import "../../../external/convex/IConvexReward.sol";
import "../../../external/convex/IConvex.sol";

import "../../enums/ProtocolEnum.sol";

import "hardhat/console.sol";

abstract contract ConvexBaseStrategy is BaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IConvex internal constant BOOSTER =
        IConvex(address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31));
    address private constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address private constant CVX = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    address internal lpToken;
    uint256 private pid;

    function _initialize(
        address _vault,
        address _harvester,
        address[] memory _wants
    ) internal {
        super._initialize(_vault, _harvester, uint16(ProtocolEnum.Convex), _wants);
        pid = getRewardPool().pid();
        lpToken = BOOSTER.poolInfo(pid).lptoken;
        isWantRatioIgnorable = true;
    }

    function getRewardPool() internal pure virtual returns(IConvexReward);

    /// @dev override method should allow to deposit multi tokens
    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        virtual
        returns (uint256);

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        console.log('start to depositTo3rdPool');
        // add liquidity on curve
        uint256 liquidity = curveAddLiquidity(_assets, _amounts);
        console.log("curveLpAmount:%d", liquidity);
        if (liquidity > 0) {
            console.log("deposit into Convex, pid:%d, lp amount:%d", pid, balanceOfToken(lpToken));
            IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), 0);
            IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), liquidity);
            // deposit into convex booster and stake at reward pool automically
            BOOSTER.deposit(pid, liquidity, true);
        }
    }

    /// @dev do not remove with one coin, and return underlying
    function curveRemoveLiquidity(uint256 liquidity, uint256 _outputCode) internal virtual;

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares, uint256 _outputCode) internal override {
        uint256 _lpAmount = (balanceOfLpToken() * _withdrawShares) / _totalShares;
        console.log("_withdrawSomeLpToken:%d", _lpAmount);
        if (_lpAmount > 0) {
            // unstaking
            getRewardPool().withdraw(_lpAmount, false);
            BOOSTER.withdraw(pid, _lpAmount);
            console.log('lpBalance:%d', balanceOfToken(lpToken));
            // remove liquidity on curve
            curveRemoveLiquidity(_lpAmount,_outputCode);
        }
    }

    function claimRewards()
        internal
        override
        virtual
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        getRewardPool().getReward();
        _rewardTokens = new address[](2);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        _claimAmounts = new uint256[](2);
        _claimAmounts[0] = balanceOfToken(CRV);
        _claimAmounts[1] = balanceOfToken(CVX);
    }

    function balanceOfLpToken() internal view returns (uint256) {
        return getRewardPool().balanceOf(address(this));
    }
}
