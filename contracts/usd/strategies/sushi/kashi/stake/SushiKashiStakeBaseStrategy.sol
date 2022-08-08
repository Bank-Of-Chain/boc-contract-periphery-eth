// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "hardhat/console.sol";
import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";

import "../../../../enums/ProtocolEnum.sol";
import "../../../../../external/sushi/kashi/IKashiPair.sol";
import "../../../../../external/sushi/IMasterChef.sol";

abstract contract SushiKashiStakeBaseStrategy is BaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IBentoBoxMinimal public bentoBox;
    IMasterChef public constant masterChef =
        IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address public constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    uint256 public constant KASHI_MINIMUM = 1000;

    /**
     * @param _vault Our vault address
     * @param _underlyingToken Lending asset
     */
    function _initialize(
        address _vault,
        address _harvester,
        address _underlyingToken
    ) internal {
        address[] memory _wants = new address[](1);
        _wants[0] = _underlyingToken;
        super._initialize(_vault, _harvester, uint16(ProtocolEnum.Sushi_Kashi), _wants);
        bentoBox = getKashiPair().bentoBox();
    }

    function getPoolId() public pure virtual returns (uint16);

    function getKashiPair() public pure virtual returns (IKashiPair);

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

        uint256[] memory ratioArray = new uint256[](1);
        ratioArray[0] = decimalUnitOfToken(_assets[0]);
        _ratios = ratioArray;
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
        _amounts[0] = estimatedTotalAmounts();
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        IKashiPair _kashiPair = getKashiPair();
        IBentoBoxMinimal _bentoBox = bentoBox;
        address _want = wants[0];
        (uint128 totalAssetElastic, ) = _kashiPair.totalAsset();
        (uint128 totalBorrowElastic, ) = _kashiPair.totalBorrow();
        uint256 allShare = totalAssetElastic + _bentoBox.toShare(_want, totalBorrowElastic, true);
        uint256 allAmount = _bentoBox.toAmount(_want, allShare, false);
        return queryTokenValue(_want, allAmount);
    }

    function claimRewards()
        internal
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        getKashiPair().accrue();
        masterChef.deposit(getPoolId(), 0);
        _rewardsTokens = new address[](1);
        _rewardsTokens[0] = SUSHI;
        _claimAmounts = new uint256[](1);
        _claimAmounts[0] = balanceOfToken(SUSHI);
        console.log("[%s] claim rewards sushi balance is %d", this.name(), _claimAmounts[0]);
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        IKashiPair _kashiPair = getKashiPair();
        IBentoBoxMinimal _bentoBox = bentoBox;
        address _asset = _assets[0];
        uint256 _amount = _amounts[0];
        // 1. ACTION_BENTO_SETAPPROVAL
        _bentoBox.setMasterContractApproval(
            // approval info
            address(this),
            _kashiPair.masterContract(),
            true,
            // empty signature
            uint8(0),
            bytes32(0),
            bytes32(0)
        );
        console.log("[%s] set master contract approval successfully", this.name());
        // 2. ACTION_BENTO_DEPOSIT
        IERC20Upgradeable(_asset).safeApprove(address(_bentoBox), 0);
        IERC20Upgradeable(_asset).safeApprove(address(_bentoBox), _amount);
        (, uint256 shareOut) = _bentoBox.deposit(_asset, address(this), address(this), _amount, 0);
        console.log("[%s] deposit bento successfully", this.name());
        console.log("[%s] share out is %d", this.name(), shareOut);
        // 3. ACTION_ADD_ASSET
        uint256 lpAmount = _kashiPair.addAsset(address(this), false, shareOut);
        console.log("[%s] add asset successfully", this.name());
        console.log("[%s] lp amount is %d", this.name(), lpAmount);
        // 4. deposit into MasterChef
        IERC20Upgradeable(address(_kashiPair)).safeApprove(address(masterChef), 0);
        IERC20Upgradeable(address(_kashiPair)).safeApprove(address(masterChef), lpAmount);
        masterChef.deposit(getPoolId(), lpAmount);
        console.log("[%s] deposit successfully", this.name());
    }

    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        uint256 _lpAmount = balanceOfLpToken();
        if (_lpAmount == 0 || _withdrawShares == 0) {
            return;
        }
        IKashiPair _kashiPair = getKashiPair();
        address _want = wants[0];
        uint256 _withdrawAmount = (_lpAmount * _withdrawShares) / _totalShares;
        console.log("[%s] lp amount wanted is %d, lp amount is %d", this.name(), _withdrawAmount, balanceOfLpToken());
        // 1. withdraw from MasterChef
        masterChef.withdraw(getPoolId(), _withdrawAmount);
        console.log("[%s] withdraw successfully", this.name());
        (, uint128 base) = _kashiPair.totalAsset();
        console.log("[%s] kashiPair totalAsset base is %d", this.name(), base);
        uint256 pairLeft = base - _withdrawAmount;
        if (pairLeft < KASHI_MINIMUM) {
            _withdrawAmount = _withdrawAmount - (KASHI_MINIMUM - pairLeft);
            console.log("[%s] kashi totalSupply will be less than minimum, so cut the withdrawn lp amount", pairLeft);
        }
        // 2. ACTION_REMOVE_ASSET
        uint256 share = _kashiPair.removeAsset(address(this), _withdrawAmount);
        console.log("[%s] remove asset successfully", this.name());
        console.log("[%s] share is %d", this.name(), share);
        // 3. ACTION_BENTO_WITHDRAW
        bentoBox.withdraw(_want, address(this), address(this), 0, share);
        console.log("[%s] real amount out is %d", this.name(), IERC20Upgradeable(_want).balanceOf(address(this)));
    }

    function balanceOfLpToken() public view returns (uint256) {
        return masterChef.userInfo(getPoolId(), address(this)).amount;
    }

    function estimatedDepositedAmounts() private view returns (uint256) {
        IKashiPair _kashiPair = getKashiPair();
        IBentoBoxMinimal _bentoBox = bentoBox;
        address _want = wants[0];
        (uint128 totalAssetElastic, uint128 totalAssetBase) = _kashiPair.totalAsset();
        // totalAssetBase == 0 => totalSupply == 0
        if (totalAssetBase == 0) {
            return 0;
        }
        (uint128 totalBorrowElastic, ) = _kashiPair.totalBorrow();
        uint256 allShare = totalAssetElastic + _bentoBox.toShare(_want, totalBorrowElastic, true);
        uint256 share = (balanceOfLpToken() * allShare) / totalAssetBase;
        uint256 amount = _bentoBox.toAmount(_want, share, false);
        return amount;
    }

    function estimatedTotalAmounts() private view returns (uint256) {
        uint256 totalAmounts = estimatedDepositedAmounts();
        uint256 wantsBalance = balanceOfToken(wants[0]);
        if (wantsBalance > 0) {
            totalAmounts += wantsBalance;
        }
        return totalAmounts;
    }
}
