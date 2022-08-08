// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "../strategies/ETHBaseStrategy.sol";
import "./Mock3rdEthPool.sol";

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract MockEthStrategy is ETHBaseStrategy {
    Mock3rdEthPool mock3rdPool;
    address private constant stETH = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    function initialize(
        address _vault,
        address _mock3rdPool
    ) public initializer {
        console.log("MockEthStrategy--initialize");
        mock3rdPool = Mock3rdEthPool(payable(_mock3rdPool));

        address[] memory _wants = new address[](2);
        _wants[0] = NativeToken.NATIVE_TOKEN;
        _wants[1] = stETH;
        super._initialize(_vault, 23, _wants);
    }

    function getVersion()
        external
        pure
        override
        returns (string memory)
    {
        return "0.0.1";
    }

    function name() external pure virtual override returns (string memory) {
        return "MockEthStrategy";
    }

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
            bool isETH,
            uint256 ethValue
        )
    {
        _tokens = wants;
        _amounts = new uint256[](2);
        _amounts[0] = address(mock3rdPool).balance;
        _amounts[1] = IERC20Upgradeable(stETH).balanceOf(address(mock3rdPool));
    }

    function get3rdPoolAssets()
        external
        view
        override
        returns (uint256)
    {
        return 50_000_000 * 1e18;
    }

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

    function depositTo3rdPool(
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal override {
        IERC20Upgradeable(stETH).approve(address(mock3rdPool), 0);
        IERC20Upgradeable(stETH).approve(address(mock3rdPool), _amounts[1]);
        mock3rdPool.deposit{value: _amounts[0]}(_assets, _amounts);
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares,uint256 _outputCode)
        internal
        override
    {
        mock3rdPool.withdraw();
    }

}
