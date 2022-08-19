// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../external/uniswap/IUniswapV3.sol";
import "../../../external/uniswap/IQuoter.sol";
import "../uniswapv3/ETHUniswapV3BaseStrategy.sol";
import "../../../external/stakewise/IPool.sol";

contract StakeWiseReth2Seth2500Strategy is ETHUniswapV3BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // https://info.uniswap.org/#/pools/0xa9ffb27d36901f87f1d0f20773f7072e38c5bfba
    address internal constant uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address internal constant sETH2 = 0xFe2e637202056d30016725477c5da089Ab0A043A;
    address internal constant swise = 0x48C3399719B582dD63eB5AADf12A40B4C3f52FA2;

    function initialize(address _vault, string memory _name) public initializer {
        uniswapV3Initialize(0xa9ffb27d36901F87f1D0F20773f7072e38C5bfbA, 10, 10, 41400, 0, 100, 60, 10);
        address[] memory _wants = new address[](2);
        _wants[0] = token0;
        _wants[1] = token1;
        super._initialize(_vault, uint16(ProtocolEnum.StakeWise), _name, _wants);
    }

    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory outputsInfo){
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info = outputsInfo[0];
        info.outputCode = 0;
        info.outputTokens = wants;
    }

    function claimRewards() internal override returns (bool isWorth, address[] memory assets, uint256[] memory amounts) {
        super.claimRewards();
        swapRewardsToWants();
    }

    function swapRewardsToWants() internal override {
        uint256 balanceOfSwise = balanceOfToken(swise);
        if (balanceOfSwise > 0) {
            IERC20(swise).approve(uniswapV3Router, 0);
            IERC20(swise).approve(uniswapV3Router, balanceOfSwise);
            IUniswapV3.ExactInputSingleParams memory params = IUniswapV3.ExactInputSingleParams(swise, sETH2, 3000, address(this), block.timestamp, balanceOfSwise, 0, 0);
            IUniswapV3(uniswapV3Router).exactInputSingle(params);
        }
    }
}
