// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "boc-contract-core/contracts/strategy/BaseStrategy.sol";
import "./../../../enums/ProtocolEnum.sol";
import "../../../../external/yearn/IYearnVault.sol";

/// @title YearnEarnStrategy
/// @notice Investment strategy for investing stablecoins via Yearn
/// @author Bank of Chain Protocol Inc
contract YearnEarnStrategy is BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address underlyingToken;
    IYearnVault yVault;

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _harvester The harvester contract address
    /// @param _name The name of strategy
    /// @param _yVault The yearn vault address
    /// @param _underlyingToken The lending asset of the Vault contract
    function initialize(
        address _vault,
        address _harvester,
        string memory _name,
        address _yVault,
        address _underlyingToken
    ) external initializer {
        yVault = IYearnVault(_yVault);
        underlyingToken = _underlyingToken;
        address[] memory _wants = new address[](1);
        _wants[0] = underlyingToken;
        _initialize(_vault, _harvester, _name, uint16(ProtocolEnum.YearnEarn), _wants);

        isWantRatioIgnorable = true;
    }

    /// @notice Return the version of strategy
    function getVersion() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @notice Return the third party protocol's pool total assets in USD.
    function get3rdPoolAssets() external view override returns (uint256 targetPoolTotalAssets) {
        targetPoolTotalAssets = queryTokenValue(wants[0], yVault.calcPoolValueInToken());
    }

    /// @notice Return the underlying token list and ratio list needed by the strategy
    /// @return _assets the address list of token to deposit
    /// @return _ratios the ratios list of `_assets`. 
    ///     The ratio is the proportion of each asset to total assets
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

    /// @notice Return the output path list of the strategy when withdraw.
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

    /// @notice Returns the position details of the strategy.
    /// @return _tokens The list of the position token
    /// @return _amounts The list of the position amount
    /// @return _isUsd Whether to count in USD
    /// @return _usdValue The USD value of positions held
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
        _amounts = new uint256[](1);

        _amounts[0] = _estimatedDepositedAssets() + balanceOfToken(underlyingToken);
    }

    /// @notice Estimates deposited assets(in usd)
    function estimatedDepositedAssets() public view returns (uint256 depositedAssets) {
        depositedAssets = queryTokenValue(wants[0], _estimatedDepositedAssets());
    }

    /// @notice Estimates deposited assets in wants[0]
    function _estimatedDepositedAssets() public view returns (uint256 depositedAssets) {
        IYearnVault _yVault = yVault;
        depositedAssets =
            (_yVault.calcPoolValueInToken() * balanceOfToken(address(_yVault))) /
            _yVault.totalSupply();
    }

    /// @notice Strategy withdraw the funds from third party pool
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        IYearnVault _yVault = yVault;
        uint256 _lpAmount = (balanceOfToken(address(_yVault)) * _withdrawShares) / _totalShares;
        if (_lpAmount > 0) {
            _yVault.withdraw(_lpAmount);
        }
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets deposit token address
    /// @param _amounts deposit token amount
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
