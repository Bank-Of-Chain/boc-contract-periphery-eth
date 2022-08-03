// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../utils/actions/UniswapV2LiquidityActionsMixin.sol";
import "../../../external/uniswap/IUniswapV2Pair.sol";
import "./../../enums/ProtocolEnum.sol";
import "../ETHBaseStrategy.sol";
import "hardhat/console.sol";

contract UniswapV2StEthWEthStrategy is ETHBaseStrategy, UniswapV2LiquidityActionsMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IUniswapV2Pair internal constant uniswapV2Pair = IUniswapV2Pair(0x4028DAAC072e492d34a3Afdbef0ba7e35D8b55C4);
    address internal constant stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84; //pairToken0
    address internal constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //pairToken1

    function initialize(address _vault) external {
        address[] memory _wants = new address[](2);
        _wants[0] = stETH;
        _wants[1] = wETH;
        _initialize(_vault, uint16(ProtocolEnum.UniswapV2), _wants);
        _initializeUniswapV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.0";
    }

    function name() public pure override returns (string memory) {
        return "UniswapV2StEthWEthStrategy";
    }

    function getWantsInfo() external view virtual override returns (address[] memory _assets, uint256[] memory _ratios) {
        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();
        _assets = wants;
        _ratios = new uint256[](2);
        _ratios[0] = reserve0;
        _ratios[1] = reserve1;
    }

    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory outputsInfo){
        outputsInfo = new OutputInfo[](1);
        OutputInfo memory info = outputsInfo[0];
        info.outputCode = 0;
        info.outputTokens = wants;
    }

    function getPositionDetail()
        public
        view
        virtual
        override
        returns (
            address[] memory _tokens,
            uint256[] memory _amounts,
            bool isETH,
            uint256 ethValue
        )
    {
        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();
        uint256 totalSupply = uniswapV2Pair.totalSupply();
        uint256 lpAmount = balanceOfToken(address(uniswapV2Pair));
        _tokens = wants;
        _amounts = new uint256[](2);
        _amounts[0] = (lpAmount * reserve0) / totalSupply + balanceOfToken(_tokens[0]);
        _amounts[1] = (lpAmount * reserve1) / totalSupply + balanceOfToken(_tokens[1]);
    }

    function lpValueInEth() internal view returns (uint256 lpValue) {
        uint256 totalSupply = uniswapV2Pair.totalSupply();
        (uint112 reserve0, uint112 reserve1, ) = uniswapV2Pair.getReserves();
        console.log('reserve0:%d,reserve1:%d',reserve0,reserve1);
        uint256 lpDecimalUnit = 1e18;
        uint256 part0 = (uint256(reserve0) * (lpDecimalUnit)) / totalSupply;
        uint256 part1 = (uint256(reserve1) * (lpDecimalUnit)) / totalSupply;
        uint256 partValue0 = priceOracle.valueInEth(stETH, part0);
        uint256 partValue1 = priceOracle.valueInEth(wETH, part1);
        lpValue = partValue0 + partValue1;
    }

    function get3rdPoolAssets() external view virtual override returns (uint256) {
        
        uint256 totalSupply = uniswapV2Pair.totalSupply();
        uint256 lpValue = lpValueInEth();

        return (totalSupply * lpValue) / 1e18;
    }

    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal virtual override {
        __uniswapV2Lend(address(this), _assets[0], _assets[1], _amounts[0], _amounts[1], 0, 0);
    }

    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares,uint256 _outputCode) internal virtual override {
        uint256 withdrawAmount = (balanceOfToken(address(uniswapV2Pair)) * _withdrawShares) / _totalShares;
        if (withdrawAmount > 0) {
            __uniswapV2Redeem(address(this), address(uniswapV2Pair), withdrawAmount, stETH, wETH, 0, 0);
        }
    }

}
