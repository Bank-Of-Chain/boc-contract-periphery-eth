// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/library/BocRoles.sol";
import "boc-contract-core/contracts/library/StableMath.sol";
import "../oracle/IPriceOracle.sol";
import "../vault/IETHVault.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";

abstract contract ETHBaseStrategy is Initializable, AccessControlMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StableMath for uint256;

    struct OutputInfo {
        uint256 outputCode; //0：default path，Greater than 0：specify output path
        address[] outputTokens; //output tokens
    }

    event Borrow(address[] _assets, uint256[] _amounts);

    event Repay(
        uint256 _withdrawShares,
        uint256 _totalShares,
        address[] _assets,
        uint256[] _amounts
    );

    event SetIsWantRatioIgnorable(bool _oldValue, bool _newValue);

    event SwapRewardsToWants(
        address _strategy,
        address[] _rewards,
        uint256[] _rewardAmounts,
        address[] _wants,
        uint256[] _wantAmounts
    );

    IETHVault public vault;
    IPriceOracle public priceOracle;
    uint16 public protocol;
    string public name;
    address[] public wants;
    bool public isWantRatioIgnorable;


    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    function _initialize(
        address _vault,
        uint16 _protocol,
        string memory _name,
        address[] memory _wants
    ) internal {
        protocol = _protocol;
        vault = IETHVault(_vault);

        priceOracle = IPriceOracle(vault.priceProvider());

        _initAccessControl(vault.accessControlProxy());

        name = _name;
        require(_wants.length > 0, "wants is required");
        wants = _wants;
    }

    /// @notice Version of strategy
    function getVersion() external pure virtual returns (string memory);


    /// @notice True means that can ignore ratios given by wants info
    function setIsWantRatioIgnorable(bool _isWantRatioIgnorable) external isVaultManager {
        bool _oldValue = isWantRatioIgnorable;
        isWantRatioIgnorable = _isWantRatioIgnorable;
        emit SetIsWantRatioIgnorable(_oldValue, _isWantRatioIgnorable);
    }

    /// @notice Provide the strategy need underlying token and ratio
    function getWantsInfo()
        external
        view
        virtual
        returns (address[] memory _assets, uint256[] memory _ratios);

    /// @notice Provide the strategy need underlying tokens
    function getWants() external view returns (address[] memory) {
        return wants;
    }

    // @notice Provide the strategy output path when withdraw.
    function getOutputsInfo() external view virtual returns (OutputInfo[] memory _outputsInfo);

    /// @notice Returns the position details or ETH value of the strategy.
    function getPositionDetail()
        public
        view
        virtual
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        );

    /// @notice Total assets of strategy in ETH.
    function estimatedTotalAssets() external view returns (uint256 _assetsInETH) {
        (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        ) = getPositionDetail();
        if (_isETH) {
            _assetsInETH = _ethValue;
        } else {
            for (uint256 i = 0; i < _tokens.length; i++) {
                uint256 _amount = _amounts[i];
                if (_amount > 0) {
                    _assetsInETH += queryTokenValueInETH(_tokens[i], _amount);
                }
            }
        }
    }

    /// @notice 3rd prototcol's pool total assets in ETH.
    function get3rdPoolAssets() external view virtual returns (uint256);

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest() external virtual returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts){
        vault.report(_rewardsTokens,_claimAmounts);
    }

    /// @notice Strategy borrow funds from vault
    /// @param _assets borrow token address
    /// @param _amounts borrow token amount
    function borrow(address[] memory _assets, uint256[] memory _amounts)
        external
        payable
        onlyVault
    {
        depositTo3rdPool(_assets, _amounts);

        emit Borrow(_assets, _amounts);
    }

    /// @notice Strategy repay the funds to vault
    /// @param _repayShares Numerator
    /// @param _totalShares Denominator
    function repay(
        uint256 _repayShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) public virtual onlyVault returns (address[] memory _assets, uint256[] memory _amounts) {
        require(_repayShares > 0 && _totalShares >= _repayShares, "cannot repay 0 shares");
        _assets = wants;
        uint256[] memory _balancesBefore = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            _balancesBefore[i] = balanceOfToken(_assets[i]);
        }

        withdrawFrom3rdPool(_repayShares, _totalShares,_outputCode);
        _amounts = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _balanceAfter = balanceOfToken(_assets[i]);
            _amounts[i] =
                _balanceAfter -
                _balancesBefore[i] +
                (_balancesBefore[i] * _repayShares) /
                _totalShares;
        }

        transferTokensToTarget(address(vault), _assets, _amounts);

        emit Repay(_repayShares, _totalShares, _assets, _amounts);
    }

    /// @notice Strategy deposit funds to 3rd pool.
    /// @param _assets deposit token address
    /// @param _amounts deposit token amount
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        virtual;

    /// @notice Strategy withdraw the funds from 3rd pool.
    /// @param _withdrawShares Numerator
    /// @param _totalShares Denominator
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal virtual;

    function balanceOfToken(address _tokenAddress) internal view returns (uint256) {
        if (_tokenAddress == NativeToken.NATIVE_TOKEN) {
            return address(this).balance;
        }
        return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
    }

    /// @notice Investable amount of strategy in ETH
    function poolQuota() public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Query the ETH value of Token.
    function queryTokenValueInETH(address _token, uint256 _amount)
        internal
        view
        returns (uint256 _valueInETH)
    {
        if (_token == NativeToken.NATIVE_TOKEN) {
            _valueInETH = _amount;
        } else {
            _valueInETH = priceOracle.valueInEth(_token, _amount);
        }
    }

    function decimalUnitOfToken(address _token) internal view returns (uint256) {
        if (_token == NativeToken.NATIVE_TOKEN) {
            return 1e18;
        }
        return 10**IERC20MetadataUpgradeable(_token).decimals();
    }

    function transferTokensToTarget(
        address _target,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _amount = _amounts[i];
            if (_amount > 0) {
                if (_assets[i] == NativeToken.NATIVE_TOKEN) {
                    payable(_target).transfer(_amount);
                } else {
                    IERC20Upgradeable(_assets[i]).safeTransfer(address(_target), _amount);
                }
            }
        }
    }
    
}
