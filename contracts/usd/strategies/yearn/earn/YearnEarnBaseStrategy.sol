// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "./../../../enums/ProtocolEnum.sol";
import "../../../../external/yearn/IYearnVault.sol";

abstract contract YearnEarnBaseStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address underlyingToken;
    IYearnVault yVault;

    function _initialize(
        address _vault,
        address _harvester,
        address _yVault,
        address _underlyingToken
    ) internal {
        yVault = IYearnVault(_yVault);
        underlyingToken = _underlyingToken;
        address[] memory _wants = new address[](1);
        _wants[0] = underlyingToken;
        _initialize(_vault, _harvester, uint16(ProtocolEnum.YearnEarn), _wants);

        isWantRatioIgnorable = true;
    }

    // ==== External === //
    function get3rdPoolAssets() external view override returns (uint256 targetPoolTotalAssets) {
        targetPoolTotalAssets = queryTokenValue(wants[0], yVault.calcPoolValueInToken());
    }

    // ==== Public ==== //
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
        _amounts = new uint256[](1);
        
        _amounts[0] = _estimatedDepositedAssets() + balanceOfToken(underlyingToken);

        console.log("[%s] getPositionDetail: %s", this.name(), _amounts[0]);
    }

    /**
     *   estimated Deposited Assets(in usd)
     */
    function estimatedDepositedAssets() public view returns (uint256 depositedAssets) {
        depositedAssets = queryTokenValue(wants[0], _estimatedDepositedAssets());
        console.log("[%s] estimatedDepositedAssets:%s", this.name(), depositedAssets);
    }

    /**
        estimated deposited assets in wants[0]
     */
    function _estimatedDepositedAssets() public view returns (uint256 depositedAssets) {
        IYearnVault _yVault = yVault;
        depositedAssets = _yVault.calcPoolValueInToken()  * balanceOfToken(address(_yVault)) / _yVault.totalSupply();
        console.log("[%s] _estimatedDepositedAssets:%s", this.name(), depositedAssets);
    }

    // ==== Internal ==== //
    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares) internal override {
        IYearnVault _yVault = yVault;
        uint256 _lpAmount = balanceOfToken(address(_yVault)) * _withdrawShares / _totalShares;
        if(_lpAmount > 0){
            _yVault.withdraw(_lpAmount);
        }
    }

    // ==== Private ==== //

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        address _underlyingToken = underlyingToken;
        require(_amounts[0] > 0);
        IYearnVault _yVault = yVault;
        IERC20Upgradeable(_underlyingToken).safeApprove(address(_yVault), 0);
        IERC20Upgradeable(_underlyingToken).safeApprove(address(_yVault), _amounts[0]);
        _yVault.deposit(_amounts[0]);
    }
}
