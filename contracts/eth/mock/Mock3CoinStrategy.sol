// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/library/BocRoles.sol";
import "../../library/ETHToken.sol";
import "boc-contract-core/contracts/library/StableMath.sol";
import "../oracle/IPriceOracle.sol";
import "../vault/IETHVault.sol";

import "hardhat/console.sol";

contract MockS3CoinStrategy is Initializable, AccessControlMixin {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IETHVault public vault;
    IPriceOracle public valueInterpreter;
    uint16 public protocol;
    address[] public wants;
    bool public isWantRatioIgnorable;

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    function initialize(address _vault) public initializer {
        address[] memory _wants = new address[](2);
        // stETH
        _wants[0] = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        // ETH
        _wants[1] = ETHToken.NATIVE_TOKEN;
        protocol = 32;
        vault = IETHVault(_vault);
        valueInterpreter = IPriceOracle(vault.priceProvider());

        _initAccessControl(vault.accessControlProxy());

        require(_wants.length > 0, "wants is required");

        wants = _wants;
        isWantRatioIgnorable = true;
    }

    function getVersion() external pure virtual returns (string memory) {
        return "1.0.0";
    }

    function name() external pure virtual returns (string memory) {
        return "MockS3CoinStrategy";
    }

    /// @notice True means that can ignore ratios given by wants info
    function setIsWantRatioIgnorable(bool _isWantRatioIgnorable) external isVaultManager {
        bool oldValue = isWantRatioIgnorable;
        isWantRatioIgnorable = _isWantRatioIgnorable;
        // emit SetIsWantRatioIgnorable(oldValue, _isWantRatioIgnorable);
    }

    function getWantsInfo() external view virtual returns (address[] memory _assets, uint256[] memory _ratios) {
        _assets = wants;

        _ratios = new uint256[](2);
        _ratios[0] = 10**IERC20MetadataUpgradeable(wants[0]).decimals() * 2;
        _ratios[1] = 10**18;
    }

    /// @notice Provide the strategy need underlying tokens
    function getWants() external view returns (address[] memory) {
        return wants;
    }

    /// @notice Returns the position details of the strategy.
    function getPositionDetail()
        public
        view
        virtual
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool isUsd,
            uint256 usdValue
        )
    {
        _tokens = new address[](wants.length);
        _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i] = wants[i];
            _amounts[i] = balanceOfToken(_tokens[i]);
        }
    }

    function get3rdPoolAssets() external view virtual returns (uint256) {
        return type(uint256).max;
    }

    function getPendingRewards() public view virtual returns (address[] memory _rewardsTokens, uint256[] memory _pendingAmounts) {
        _rewardsTokens = new address[](0);
        _pendingAmounts = new uint256[](0);
    }

    function claimRewards() internal virtual returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts) {
        _rewardsTokens = new address[](0);
        _claimAmounts = new uint256[](0);
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal virtual {}

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares, uint256 _outputCode) internal virtual {
        // _assets = new address[](wants.length);
        // _amounts = new uint256[](_assets.length);
        // for (uint256 i = 0; i < _assets.length; i++) {
        //     _assets[i] = wants[i];
        //     _amounts[i] =
        //         (IERC20Upgradeable(_assets[i]).balanceOf(address(this)) *
        //             _withdrawShares) /
        //         _totalShares;
        // }
    }

    function protectedTokens() internal view virtual returns (address[] memory) {
        return wants;
    }

    /// @notice Total assets of strategy in USD.
    function estimatedTotalAssets() external view virtual returns (uint256) {
        (address[] memory tokens, uint256[] memory amounts, bool isETH, uint256 ethValue) = getPositionDetail();
        if (isETH) {
            return ethValue;
        } else {
            uint256 totalETHValue = 0;
            for (uint256 i = 0; i < tokens.length; i++) {
                uint256 amount = amounts[i];
                if (amount > 0) {
                    totalETHValue += valueInterpreter.valueInEth(tokens[i], amount);
                }
            }
            return totalETHValue;
        }
    }

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest() external payable virtual returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts) {
        claimRewards();
        vault.report();
    }

    /// @notice Strategy borrow funds from vault
    /// @param _assets borrow token address
    /// @param _amounts borrow token amount
    function borrow(address[] memory _assets, uint256[] memory _amounts) external payable onlyVault {
        depositTo3rdPool(_assets, _amounts);
        // emit Borrow(_assets, _amounts);
    }

    /// @notice Strategy repay the funds to vault
    /// @param _repayShares Numerator
    /// @param _totalShares Denominator
    function repay(uint256 _repayShares, uint256 _totalShares, uint256 _outputCode) public virtual onlyVault returns (address[] memory _assets, uint256[] memory _amounts) {
        require(_repayShares > 0 && _totalShares >= _repayShares, "cannot repay 0 shares");
        _assets = wants;
        uint256[] memory balancesBefore = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            balancesBefore[i] = balanceOfToken(_assets[i]);
        }

        withdrawFrom3rdPool(_repayShares, _totalShares, _outputCode);
        _amounts = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 balanceAfter = balanceOfToken(_assets[i]);
            _amounts[i] = balanceAfter - balancesBefore[i] + (balancesBefore[i] * _repayShares) / _totalShares;
        }

        transferTokensToTarget(address(vault), _assets, _amounts);

        // emit Repay(_repayShares, _totalShares, _assets, _amounts);
    }

    function balanceOfToken(address tokenAddress) internal view returns (uint256) {
        if (tokenAddress == ETHToken.NATIVE_TOKEN) {
            return address(this).balance;
        }
        return IERC20Upgradeable(tokenAddress).balanceOf(address(this));
    }

    /// @notice Investable amount of strategy in USD
    function poolQuota() public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Removes tokens from this Strategy that are not the type of token managed by this Strategy.
    /// @param _token： The token to transfer out of this vault.
    function sweep(address _token) external isKeeper {
        require(!(arrayContains(wants, _token) || arrayContains(protectedTokens(), _token)), "protected token");
        IERC20Upgradeable(_token).safeTransfer(vault.treasury(), balanceOfToken(_token));
    }

    /// @notice Query the value of Token.
    function queryTokenValue(address _token, uint256 _amount) internal view returns (uint256 valueInUSD) {
        valueInUSD = valueInterpreter.valueInUsd(_token, _amount);
    }

    function decimalUnitOfToken(address _token) internal view returns (uint256) {
        return 10**IERC20MetadataUpgradeable(_token).decimals();
    }

    function transferTokensToTarget(
        address _target,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 amount = _amounts[i];
            address _asset = _assets[i];
            if (amount > 0) {
                if (_asset == ETHToken.NATIVE_TOKEN) {
                    payable(_target).transfer(amount);
                } else {
                    IERC20Upgradeable(_asset).safeTransfer(_target, amount);
                }
            }
        }
    }

    function arrayContains(address[] memory array, address key) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == key) {
                return true;
            }
        }
        return false;
    }
}
