// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../external/uniswap/IUniswapV3.sol";
import "../../../external/uniswap/IQuoter.sol";
import "../uniswapv3/ETHUniswapV3BaseStrategy.sol";
import "../../../external/stakewise/IPool.sol";

contract StakeWiseEthSeth23000Strategy is ETHUniswapV3BaseStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // https://info.uniswap.org/#/pools/0x7379e81228514a1d2a6cf7559203998e20598346
    address internal constant uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address internal constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant sETH2 = 0xFe2e637202056d30016725477c5da089Ab0A043A;
    address internal constant rETH2 = 0x20BC832ca081b91433ff6c17f85701B6e92486c5;

    function initialize(address _vault,string memory _name) public initializer {
        uniswapV3Initialize(0x7379e81228514a1D2a6Cf7559203998E20598346, 60, 60, 41400, 0, 100, 60,60);
        address[] memory _wants = new address[](1);
        _wants[0] = wETH;
        super._initialize(_vault, uint16(ProtocolEnum.StakeWise), _name,_wants);
    }

    function getWantsInfo() public view override returns (address[] memory _assets, uint256[] memory _ratios) {
        _assets = wants;
        _ratios = new uint256[](1);
        _ratios[0] = 1e18;
    }

    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory outputsInfo){
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info = outputsInfo[0];
        info.outputCode = 0;
        info.outputTokens = wants;
    }

    function getPositionDetail() public view override returns (address[] memory _tokens, uint256[] memory _amounts, bool isETH, uint256 ethValue) {
        _tokens = new address[](2);
        _tokens[0] = token0;
        _tokens[1] = token1;
        _amounts = new uint256[](2);
        _amounts[0] = balanceOfToken(token0);
        _amounts[1] = balanceOfToken(token1);
        (uint256 amount0, uint256 amount1) = balanceOfPoolWants(baseMintInfo);
        _amounts[0] += amount0;
        _amounts[1] += amount1;
        (amount0, amount1) = balanceOfPoolWants(limitMintInfo);
        _amounts[0] += amount0;
        _amounts[1] += amount1;
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal override {
        int24 tickLower = baseMintInfo.tickLower;
        int24 tickUpper = baseMintInfo.tickUpper;
        (, int24 tick,,,,,) = pool.slot0();
        if (baseMintInfo.tokenId == 0 || shouldRebalance(tick)) {
            (,, tickLower, tickUpper) = getSpecifiedRangesOfTick(tick);
        }
        (uint256 amount0, uint256 amount1) = super.getAmountsForLiquidity(tickLower, tickUpper, pool.liquidity());
        uint256 quoteAmountOut = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6).quoteExactInputSingle(wETH, sETH2, 3000, _amounts[0], 0);
        uint256 depositSeth2ToWethAmount = _amounts[0] * amount1 / (amount1 + amount0 * quoteAmountOut / _amounts[0]);
        uint256 depositWethAmount = _amounts[0] - depositSeth2ToWethAmount;
        IERC20(wETH).approve(uniswapV3Router, 0);
        IERC20(wETH).approve(uniswapV3Router, depositSeth2ToWethAmount);
        IUniswapV3.ExactInputSingleParams memory params = IUniswapV3.ExactInputSingleParams(wETH, sETH2, 3000, address(this), block.timestamp, depositSeth2ToWethAmount, 0, 0);
        uint256 amountOut = IUniswapV3(uniswapV3Router).exactInputSingle(params);
        _assets = new address[](2);
        _assets[0] = token0;
        _assets[1] = token1;
        uint256[] memory _ratios = new uint256[](2);
        _ratios[0] = balanceOfToken(wETH);
        _ratios[1] = balanceOfToken(sETH2);
        super.depositTo3rdPool(_assets, _amounts);
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares, uint256 _outputCode) internal override {
        super.withdrawFrom3rdPool(_withdrawShares, _totalShares,_outputCode);
        uint256 sETH2Balance = balanceOfToken(sETH2);
        if (sETH2Balance <= 0) return;
        IERC20(sETH2).approve(uniswapV3Router, 0);
        IERC20(sETH2).approve(uniswapV3Router, sETH2Balance);
        IUniswapV3.ExactInputSingleParams memory params = IUniswapV3.ExactInputSingleParams(sETH2, wETH, 3000, address(this), block.timestamp, sETH2Balance, 0, 0);
        uint256 amountOut = IUniswapV3(uniswapV3Router).exactInputSingle(params);
    }

    function claimRewards() internal override returns (bool isWorth, address[] memory assets, uint256[] memory amounts) {
        super.claimRewards();
    }
}
