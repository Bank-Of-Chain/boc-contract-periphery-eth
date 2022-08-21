// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";

import "./../../enums/ProtocolEnum.sol";
import "../../../external/dforce/DFiToken.sol";
import "../../../external/dforce/IRewardDistributorV3.sol";

contract DForceLendStrategy is BaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address internal constant DF = 0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0;
    IRewardDistributorV3 internal constant REWARD_DISTRIBUTOR_V3 =
        IRewardDistributorV3(0x8fAeF85e436a8dd85D8E636Ea22E3b90f1819564);

    address public iToken;

    function initialize(address _vault, address _harvester,string memory _name,address _underlyingToken,address _iToken) external initializer {
        address[] memory _wants = new address[](1);
        _wants[0] = _underlyingToken;
        iToken = _iToken;
        super._initialize(_vault, _harvester, _name,uint16(ProtocolEnum.DForce), _wants);
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
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info0 = _outputsInfo[0];
        _info0.outputCode = 0;
        _info0.outputTokens = wants;
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
        address _iTokenTmp = iToken;
        _tokens = wants;
        _amounts = new uint256[](1);
        _amounts[0] =
            (balanceOfToken(_iTokenTmp) * DFiToken(_iTokenTmp).exchangeRateStored()) /
            1e18 +
            balanceOfToken(_tokens[0]);
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        address _iTokenTmp = iToken;
        uint256 _iTokenTotalSupply = (DFiToken(_iTokenTmp).totalSupply() *
            DFiToken(_iTokenTmp).exchangeRateStored()) / 1e18;
        return _iTokenTotalSupply != 0 ? queryTokenValue(wants[0], _iTokenTotalSupply) : 0;
    }

    function claimRewards()
        internal
        override
        returns (address[] memory _rewardTokens, uint256[] memory _claimAmounts)
    {
        address[] memory _holders = new address[](1);
        _holders[0] = address(this);
        address[] memory _iTokens = new address[](1);
        _iTokens[0] = iToken;
        REWARD_DISTRIBUTOR_V3.claimReward(_holders, _iTokens);
        _rewardTokens = new address[](1);
        _rewardTokens[0] = DF;
        _claimAmounts = new uint256[](1);
        _claimAmounts[0] = balanceOfToken(_rewardTokens[0]);
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        uint256 _amount = _amounts[0];
        if (_amount > 0) {
            address _iTokenTmp = iToken;
            address _asset = _assets[0];
            IERC20Upgradeable(_asset).safeApprove(_iTokenTmp, 0);
            IERC20Upgradeable(_asset).safeApprove(_iTokenTmp, _amount);
            DFiToken(_iTokenTmp).mint(address(this), _amount);
        }
    }

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        address _iTokenTmp = iToken;
        uint256 _lpAmount = (balanceOfToken(_iTokenTmp) * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            DFiToken(_iTokenTmp).redeem(address(this), _lpAmount);
        }
    }
}
