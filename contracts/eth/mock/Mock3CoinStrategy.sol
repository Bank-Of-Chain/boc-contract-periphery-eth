// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "boc-contract-core/contracts/access-control/AccessControlMixin.sol";
import "boc-contract-core/contracts/library/BocRoles.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "boc-contract-core/contracts/library/StableMath.sol";
import "../oracle/IPriceOracleConsumer.sol";
import "../vault/IETHVault.sol";

/// @title MockS3CoinStrategy
/// @notice The mock contract of 3CoinStrategy ///// ????
/// @author Bank of Chain Protocol Inc
contract MockS3CoinStrategy is Initializable, AccessControlMixin {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice The ETH vault interface
    IETHVault public vault;

    /// @notice The price oracle consumer interface
    IPriceOracleConsumer public valueInterpreter;

    /// @notice The ID of protocol, init 32
    uint16 public protocol;

    /// @notice The list of tokens wanted by this strategy
    address[] public wants;

    /// @notice The boolean switch whether ignore the want ratio
    bool public isWantRatioIgnorable;

    /// @dev Modifier that checks that msg.sender is the vault or not
    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

    function initialize(address _vault) public initializer {
        address[] memory _wants = new address[](2);
        // stETH
        _wants[0] = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        // ETH
        _wants[1] = NativeToken.NATIVE_TOKEN;
        protocol = 32;
        vault = IETHVault(_vault);
        valueInterpreter = IPriceOracleConsumer(vault.priceProvider());

        _initAccessControl(vault.accessControlProxy());

        require(_wants.length > 0, "wants is required");

        wants = _wants;
        isWantRatioIgnorable = true;
    }

    /// @notice Return the version of strategy
    function getVersion() external pure virtual returns (string memory) {
        return "1.0.0";
    }

    /// @notice Return the name of strategy
    function name() external pure virtual returns (string memory) {
        return "MockS3CoinStrategy";
    }

    /// @notice True means that can ignore ratios given by wants info
    function setIsWantRatioIgnorable(bool _isWantRatioIgnorable) external isVaultManager {
        bool oldValue = isWantRatioIgnorable;
        isWantRatioIgnorable = _isWantRatioIgnorable;
        // emit SetIsWantRatioIgnorable(oldValue, _isWantRatioIgnorable);
    }

    // @notice Return the output path list of the strategy when withdraw.
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
            bool _isUsd,
            uint256 _usdValue
        )
    {
        _tokens = new address[](wants.length);
        _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i] = wants[i];
            _amounts[i] = balanceOfToken(_tokens[i]);
        }
    }

    /// @notice Return the third party protocol's pool total assets in USD.
    function get3rdPoolAssets() external view virtual returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Gets the info of pending rewards
    /// @param _rewardsTokens The address list of reward tokens
    /// @param _pendingAmounts The amount list of reward tokens
    function getPendingRewards() public view virtual returns (address[] memory _rewardsTokens, uint256[] memory _pendingAmounts) {
        _rewardsTokens = new address[](0);
        _pendingAmounts = new uint256[](0);
    }

    /// @notice Collect the rewards from third party protocol
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards() internal virtual returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts) {
        _rewardsTokens = new address[](0);
        _claimAmounts = new uint256[](0);
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal virtual {}

    /// @notice Strategy withdraw the funds from third party pool
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
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

    /// @notice Return the list of tokens wanted by this strategy
    function protectedTokens() internal view virtual returns (address[] memory) {
        return wants;
    }

    /// @notice Total assets of strategy in USD.
    function estimatedTotalAssets() external view virtual returns (uint256) {
        (address[] memory _tokens, uint256[] memory _amounts, bool _isETH, uint256 _ethValue) = getPositionDetail();
        if (_isETH) {
            return _ethValue;
        } else {
            uint256 _totalETHValue = 0;
            for (uint256 i = 0; i < _tokens.length; i++) {
                uint256 _amount = _amounts[i];
                if (_amount > 0) {
                    _totalETHValue += valueInterpreter.valueInEth(_tokens[i], _amount);
                }
            }
            return _totalETHValue;
        }
    }

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest() external payable virtual returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts) {
        claimRewards();
        vault.report(_rewardsTokens,_claimAmounts);
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
        uint256[] memory _balancesBefore = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            _balancesBefore[i] = balanceOfToken(_assets[i]);
        }

        withdrawFrom3rdPool(_repayShares, _totalShares, _outputCode);
        _amounts = new uint256[](_assets.length);
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _balanceAfter = balanceOfToken(_assets[i]);
            _amounts[i] = _balanceAfter - _balancesBefore[i] + (_balancesBefore[i] * _repayShares) / _totalShares;
        }

        transferTokensToTarget(address(vault), _assets, _amounts);

        // emit Repay(_repayShares, _totalShares, _assets, _amounts);
    }

    /// @notice Return the token's balance Of this contract
    function balanceOfToken(address _tokenAddress) internal view returns (uint256) {
        if (_tokenAddress == NativeToken.NATIVE_TOKEN) {
            return address(this).balance;
        }
        return IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
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
    function queryTokenValue(address _token, uint256 _amount) internal view returns (uint256 _valueInUSD) {
        _valueInUSD = valueInterpreter.valueInUsd(_token, _amount);
    }

    /// @notice Return the uint with decimal of one token
    function decimalUnitOfToken(address _token) internal view returns (uint256) {
        return 10**IERC20MetadataUpgradeable(_token).decimals();
    }

    /// @notice Transfer `_assets` token from this contract to target address.
    /// @param _target The target address to receive token
    /// @param _assets the address list of token to transfer
    /// @param _amounts the amount list of token to transfer
    function transferTokensToTarget(
        address _target,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 _amount = _amounts[i];
            address _asset = _assets[i];
            if (_amount > 0) {
                if (_asset == NativeToken.NATIVE_TOKEN) {
                    payable(_target).transfer(_amount);
                } else {
                    IERC20Upgradeable(_asset).safeTransfer(_target, _amount);
                }
            }
        }
    }

    /// @notice Ckecks that `_array` contains `_key` or not
    /// @param _array The address list
    /// @param _key A address 
    /// @return Returns `true` if `_array` contains `_key`, otherwise rerturns `false`
    function arrayContains(address[] memory _array, address _key) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _key) {
                return true;
            }
        }
        return false;
    }
}
