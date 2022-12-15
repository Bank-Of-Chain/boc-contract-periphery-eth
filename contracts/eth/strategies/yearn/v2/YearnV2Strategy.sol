// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../../enums/ProtocolEnum.sol";
import "../../ETHBaseStrategy.sol";
import "../../../../external/yearn/IYearnVaultV2.sol";

/// @title YearnV2Strategy
/// @notice Investment strategy for investing ETH via YearnV2
/// @author Bank of Chain Protocol Inc
contract YearnV2Strategy is ETHBaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IYearnVaultV2 public yVault;

    /// @notice Initialize this contract
    /// @param _vault The Vault contract
    /// @param _name The name of strategy
    /// @param _yVault The yearn vault address
    function initialize(
        address _vault,
        string memory _name,
        address _yVault,
        address _token
    ) external initializer {
        yVault = IYearnVaultV2(_yVault);
        address[] memory _wants = new address[](1);
        _wants[0] = _token;
        super._initialize(_vault, uint16(ProtocolEnum.YearnV2), _name, _wants);
    }

    /// @inheritdoc ETHBaseStrategy
    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo()
        external
        view
        virtual
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    /// @inheritdoc ETHBaseStrategy
    function getOutputsInfo()
        external
        view
        virtual
        override
        returns (OutputInfo[] memory _outputsInfo)
    {
        _outputsInfo = new OutputInfo[](1);
        OutputInfo memory _info = _outputsInfo[0];
        _info.outputCode = 0;
        _info.outputTokens = wants;
    }

    /// @inheritdoc ETHBaseStrategy
    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](1);
        IYearnVaultV2 _yVault = yVault;
        uint256 _balanceOf = _yVault.balanceOf(address(this));
        uint256 _pricePerShare = _yVault.pricePerShare();
        _amounts[0] = balanceOfToken(_tokens[0]) + (_balanceOf * _pricePerShare) / 1e18;
    }

    /// @inheritdoc ETHBaseStrategy
    function get3rdPoolAssets() external view override returns (uint256) {
        return queryTokenValueInETH(wants[0], yVault.totalAssets());
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        require(_amounts[0] > 0);
        address _yVaultAddress = address(yVault);
        address _token = yVault.token();
        IERC20Upgradeable(_token).safeApprove(_yVaultAddress, 0);
        IERC20Upgradeable(_token).safeApprove(_yVaultAddress, _amounts[0]);
        yVault.deposit(_amounts[0]);
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(
        uint256 _withdrawShares,
        uint256 _totalShares,
        uint256 _outputCode
    ) internal override {
        IYearnVaultV2 _yVault = yVault;
        uint256 _balanceOf = yVault.balanceOf(address(this));
        uint256 _pricePerShare = yVault.pricePerShare();
        yVault.withdraw((_balanceOf * _withdrawShares) / _totalShares);
    }
}
