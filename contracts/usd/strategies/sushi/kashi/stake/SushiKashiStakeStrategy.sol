// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "boc-contract-core/contracts/strategy/BaseClaimableStrategy.sol";

import "../../../../enums/ProtocolEnum.sol";
import "../../../../../external/sushi/kashi/IKashiPair.sol";
import "../../../../../external/sushi/IMasterChef.sol";

contract SushiKashiStakeStrategy is BaseClaimableStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IBentoBoxMinimal public bentoBox;
    IMasterChef public constant MASTERCHEF =
        IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address public constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    uint256 public constant KASHI_MINIMUM = 1000;

    IKashiPair public kashiPari; 
    uint256 public poolId;

    /**
     * @param _vault Our vault address
     * @param _underlyingToken Lending asset
     */
    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _underlyingToken,
        address _pair,
        uint256 _poolId
    ) external initializer {
        address[] memory _wants = new address[](1);
        _wants[0] = _underlyingToken;
        kashiPari = IKashiPair(_pair);
        poolId = _poolId;
        bentoBox = kashiPari.bentoBox();
        super._initialize(_vault, _harvester, _name, uint16(ProtocolEnum.Sushi_Kashi), _wants);
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

        uint256[] memory _ratioArray = new uint256[](1);
        _ratioArray[0] = decimalUnitOfToken(_assets[0]);
        _ratios = _ratioArray;
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
        _tokens = wants;
        _amounts = new uint256[](_tokens.length);
        _amounts[0] = estimatedTotalAmounts();
    }

    function get3rdPoolAssets() external view override returns (uint256) {
        IKashiPair _kashiPair = kashiPari;
        IBentoBoxMinimal _bentoBox = bentoBox;
        address _want = wants[0];
        (uint128 _totalAssetElastic, ) = _kashiPair.totalAsset();
        (uint128 _totalBorrowElastic, ) = _kashiPair.totalBorrow();
        uint256 _allShare = _totalAssetElastic + _bentoBox.toShare(_want, _totalBorrowElastic, true);
        uint256 _allAmount = _bentoBox.toAmount(_want, _allShare, false);
        return queryTokenValue(_want, _allAmount);
    }

    function claimRewards()
        internal
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        kashiPari.accrue();
        MASTERCHEF.deposit(poolId, 0);
        _rewardsTokens = new address[](1);
        _rewardsTokens[0] = SUSHI;
        _claimAmounts = new uint256[](1);
        _claimAmounts[0] = balanceOfToken(SUSHI);
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        IKashiPair _kashiPair = kashiPari;
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
        // 2. ACTION_BENTO_DEPOSIT
        IERC20Upgradeable(_asset).safeApprove(address(_bentoBox), 0);
        IERC20Upgradeable(_asset).safeApprove(address(_bentoBox), _amount);
        (, uint256 shareOut) = _bentoBox.deposit(_asset, address(this), address(this), _amount, 0);
        // 3. ACTION_ADD_ASSET
        uint256 _lpAmount = _kashiPair.addAsset(address(this), false, shareOut);
        // 4. deposit into MasterChef
        IERC20Upgradeable(address(_kashiPair)).safeApprove(address(MASTERCHEF), 0);
        IERC20Upgradeable(address(_kashiPair)).safeApprove(address(MASTERCHEF), _lpAmount);
        MASTERCHEF.deposit(poolId, _lpAmount);
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
        IKashiPair _kashiPair = kashiPari;
        address _want = wants[0];
        uint256 _withdrawAmount = (_lpAmount * _withdrawShares) / _totalShares;
        // 1. withdraw from MasterChef
        MASTERCHEF.withdraw(poolId, _withdrawAmount);
        (, uint128 base) = _kashiPair.totalAsset();
        uint256 _pairLeft = base - _withdrawAmount;
        if (_pairLeft < KASHI_MINIMUM) {
            _withdrawAmount = _withdrawAmount - (KASHI_MINIMUM - _pairLeft);
        }
        // 2. ACTION_REMOVE_ASSET
        uint256 _share = _kashiPair.removeAsset(address(this), _withdrawAmount);
        // 3. ACTION_BENTO_WITHDRAW
        bentoBox.withdraw(_want, address(this), address(this), 0, _share);
    }

    function balanceOfLpToken() public view returns (uint256) {
        return MASTERCHEF.userInfo(poolId, address(this)).amount;
    }

    function estimatedDepositedAmounts() private view returns (uint256) {
        IKashiPair _kashiPair = kashiPari;
        IBentoBoxMinimal _bentoBox = bentoBox;
        address _want = wants[0];
        (uint128 _totalAssetElastic, uint128 _totalAssetBase) = _kashiPair.totalAsset();
        // _totalAssetBase == 0 => totalSupply == 0
        if (_totalAssetBase == 0) {
            return 0;
        }
        (uint128 _totalBorrowElastic, ) = _kashiPair.totalBorrow();
        uint256 _allShare = _totalAssetElastic + _bentoBox.toShare(_want, _totalBorrowElastic, true);
        uint256 _share = (balanceOfLpToken() * _allShare) / _totalAssetBase;
        uint256 _amount = _bentoBox.toAmount(_want, _share, false);
        return _amount;
    }

    function estimatedTotalAmounts() private view returns (uint256) {
        uint256 _totalAmounts = estimatedDepositedAmounts();
        uint256 _wantsBalance = balanceOfToken(wants[0]);
        if (_wantsBalance > 0) {
            _totalAmounts += _wantsBalance;
        }
        return _totalAmounts;
    }
}
