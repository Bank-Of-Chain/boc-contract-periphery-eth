// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "../strategies/ETHBaseStrategy.sol";
import "../enums/ProtocolEnum.sol";
import "./Mock3rdEthPool.sol";

/// @title MockS3CoinETHStrategy
/// @notice The mock contract of 3CoinStrategy
/// @author Bank of Chain Protocol Inc
contract MockS3CoinETHStrategy is ETHBaseStrategy {
    Mock3rdEthPool private mock3rdPool;
    address private constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address private constant W_ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function initialize(address _vault, address _mock3rdPool) public initializer {
        mock3rdPool = Mock3rdEthPool(payable(_mock3rdPool));
        address[] memory _wants = new address[](3);
        // ETH
        _wants[0] = NativeToken.NATIVE_TOKEN;
        // stETH
        _wants[1] = stETH;
        // WETH
        _wants[2] = W_ETH;
        wants = _wants;
        isWantRatioIgnorable = true;
        super._initialize(_vault, uint16(ProtocolEnum.Aave), "MockS3CoinETHStrategy", _wants);
    }

    /// @notice Return the version of strategy
    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.0";
    }

    // @notice Return the output path list of the strategy when withdraw.
    function getWantsInfo()
        external
        view
        virtual
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;

        _ratios = new uint256[](3);
        _ratios[0] = 1e18;
        _ratios[1] = 10**IERC20MetadataUpgradeable(wants[1]).decimals() * 2;
        _ratios[2] = 1e18;
    }

    /// @notice Returns the position details of the strategy.
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
        _tokens = new address[](wants.length);
        _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i] = wants[i];

            if (_tokens[i] == NativeToken.NATIVE_TOKEN) {
                _amounts[i] = balanceOfToken(_tokens[i]) + address(mock3rdPool).balance;
            } else {
                _amounts[i] =
                    balanceOfToken(_tokens[i]) +
                    IERC20Upgradeable(_tokens[i]).balanceOf(address(mock3rdPool));
            }
        }
    }

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
        _info.outputTokens = new address[](3);
        _info.outputTokens[0] = wants[0];
        _info.outputTokens[1] = wants[1];
        _info.outputTokens[2] = wants[2];
    }

    /// @notice Return the third party protocol's pool total assets in USD.
    function get3rdPoolAssets() external view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /// @notice Gets the info of pending rewards
    /// @param _rewardsTokens The address list of reward tokens
    /// @param _pendingAmounts The amount list of reward tokens
    function getPendingRewards()
        public
        view
        virtual
        returns (address[] memory _rewardsTokens, uint256[] memory _pendingAmounts)
    {
        _rewardsTokens = new address[](0);
        _pendingAmounts = new uint256[](0);
    }

    /// @notice Collect the rewards from third party protocol
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards()
        internal
        virtual
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        _rewardsTokens = new address[](0);
        _claimAmounts = new uint256[](0);
    }

    function reportWithoutClaim() external {
        vault.reportWithoutClaim();
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts)
        internal
        override
    {
        IERC20Upgradeable(stETH).approve(address(mock3rdPool), 0);
        IERC20Upgradeable(stETH).approve(address(mock3rdPool), _amounts[1]);
        IERC20Upgradeable(W_ETH).approve(address(mock3rdPool), 0);
        IERC20Upgradeable(W_ETH).approve(address(mock3rdPool), _amounts[2]);
        mock3rdPool.deposit{value: _amounts[0]}(_assets, _amounts);
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
        mock3rdPool.withdraw(_withdrawShares, _totalShares);
    }

    /// @notice Harvests the Strategy, recognizing any profits or losses and adjusting the Strategy's position.
    function harvest()
        public
        virtual
        override
        returns (address[] memory _rewardsTokens, uint256[] memory _claimAmounts)
    {
        claimRewards();
        vault.report(_rewardsTokens, _claimAmounts);
    }
}
