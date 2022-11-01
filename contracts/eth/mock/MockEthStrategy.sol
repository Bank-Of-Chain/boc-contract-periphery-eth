// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "../strategies/ETHBaseStrategy.sol";
import "./Mock3rdEthPool.sol";
import "boc-contract-core/contracts/library/NativeToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title MockEthStrategy
/// @notice The mock contract of EthStrategy
/// @author Bank of Chain Protocol Inc
contract MockEthStrategy is ETHBaseStrategy {
    Mock3rdEthPool private mock3rdPool;
    address private constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    function initialize(
        address _vault,
        address _mock3rdPool
    ) public initializer {
        mock3rdPool = Mock3rdEthPool(payable(_mock3rdPool));

        address[] memory _wants = new address[](2);
        _wants[0] = NativeToken.NATIVE_TOKEN;
        _wants[1] = stETH;
        super._initialize(_vault, 23, "MockEthStrategy",_wants);
    }

    /// @notice Return the version of strategy
    function getVersion()
        external
        pure
        override
        returns (string memory)
    {
        return "0.0.1";
    }

    // @notice Return the output path list of the strategy when withdraw.
    function getWantsInfo()
        external
        view
        override
        returns (address[] memory _assets, uint256[] memory _ratios)
    {
        _assets = wants;

        _ratios = new uint256[](2);
        _ratios[0] = 100;
        _ratios[1] = 200;
    }

    // @notice Provide the strategy output path when withdraw.
    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory outputsInfo){
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info = outputsInfo[0];
        info.outputCode = 0;
        info.outputTokens = new address[](2);
        info.outputTokens[0] = NativeToken.NATIVE_TOKEN;
        info.outputTokens[1] = stETH;
    }

    /// @notice Returns the position details of the strategy.
    function getPositionDetail()
        public
        view
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool _isETH,
            uint256 _ethValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](2);
        _amounts[0] = address(mock3rdPool).balance;
        _amounts[1] = IERC20Upgradeable(stETH).balanceOf(address(mock3rdPool));
    }

    /// @notice Return the third party protocol's pool total assets in ETH.
    function get3rdPoolAssets()
        external
        view
        override
        returns (uint256)
    {
        return 50_000_000 * 1e18;
    }

    /// @notice Gets the info of pending rewards
    /// @param _rewardsTokens The address list of reward tokens
    /// @param _pendingAmounts The amount list of reward tokens
    function getPendingRewards()
        public
        view
        returns (
            address[] memory _rewardsTokens,
            uint256[] memory _pendingAmounts
        )
    {
        (_rewardsTokens, _pendingAmounts) = mock3rdPool.getPendingRewards();
    }

    /// @notice Collect the rewards from third party protocol
    /// @return _rewardsTokens The list of the reward token
    /// @return _claimAmounts The list of the reward amount claimed
    function claimRewards()
        internal
        returns (
            address[] memory _rewardsTokens,
            uint256[] memory _claimAmounts
        )
    {
        (_rewardsTokens, ) = mock3rdPool.getPendingRewards();
        _claimAmounts = mock3rdPool.claim();
    }

    /// @notice Strategy deposit funds to third party pool.
    /// @param _assets the address list of token to deposit
    /// @param _amounts the amount list of token to deposit
    function depositTo3rdPool(
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal override {
        IERC20Upgradeable(stETH).approve(address(mock3rdPool), 0);
        IERC20Upgradeable(stETH).approve(address(mock3rdPool), _amounts[1]);
        mock3rdPool.deposit{value: _amounts[0]}(_assets, _amounts);
    }

    /// @notice Strategy withdraw the funds from third party pool
    /// @param _withdrawShares The amount of shares to withdraw
    /// @param _totalShares The total amount of shares owned by this strategy
    /// @param _outputCode The code of output
    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares,uint256 _outputCode)
        internal
        override
    {
        mock3rdPool.withdraw();
    }

}
