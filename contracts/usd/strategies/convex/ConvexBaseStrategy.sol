// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";

import "../../../external/convex/IConvexReward.sol";
import "../../../external/convex/IConvex.sol";

import "../../enums/ProtocolEnum.sol";

abstract contract ConvexBaseStrategy is BaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IConvex internal constant BOOSTER =
        IConvex(address(0xF403C135812408BFbE8713b5A23a04b3D48AAE31));
    address private constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address private constant CVX = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    address public curvePool;
    address public lpToken;
    address public rewardPool;
    uint256 public pid;

    function _initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address[] memory _wants,
        address _curvePool,
        address _rewardPool
    ) internal {
        super._initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Convex), _wants);
        curvePool = _curvePool;
        rewardPool = _rewardPool;
        pid = IConvexReward(_rewardPool).pid();
        lpToken = BOOSTER.poolInfo(pid).lptoken;
        isWantRatioIgnorable = true;
    }


    /// @dev override method should allow to deposit multi tokens
    function curveAddLiquidity(address[] memory _assets, uint256[] memory _amounts)
        internal
        virtual
        returns (uint256);

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        // add liquidity on curve
        uint256 _liquidity = curveAddLiquidity(_assets, _amounts);
        if (_liquidity > 0) {
            IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), 0);
            IERC20Upgradeable(lpToken).safeApprove(address(BOOSTER), _liquidity);
            // deposit into convex booster and stake at reward pool automically
            BOOSTER.deposit(pid, _liquidity, true);
        }
    }

    /// @dev do not remove with one coin, and return underlying
    function curveRemoveLiquidity(uint256 _liquidity, uint256 _outputCode) internal virtual;

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        uint256 _lpAmount = (balanceOfLpToken() * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            // unstaking
            IConvexReward(rewardPool).withdraw(_lpAmount, false);
            BOOSTER.withdraw(pid, _lpAmount);
            // remove liquidity on curve
            curveRemoveLiquidity(_lpAmount, _outputCode);
        }
    }

    function claimRewards()
        internal
        virtual
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        IConvexReward(rewardPool).getReward();
        _rewardTokens = new address[](2);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        _claimAmounts = new uint256[](2);
        _claimAmounts[0] = balanceOfToken(CRV);
        _claimAmounts[1] = balanceOfToken(CVX);
    }

    function balanceOfLpToken() internal view returns (uint256) {
        return IConvexReward(rewardPool).balanceOf(address(this));
    }
}
