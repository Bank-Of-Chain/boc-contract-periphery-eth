// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../../utils/actions/UniswapV2LiquidityActionsMixin.sol";
import "../../../external/uniswap/IUniswapV2Pair.sol";
import "./../../enums/ProtocolEnum.sol";
import "../ETHBaseStrategy.sol";

/// @title ETHUniswapV2Strategy
/// @notice Investment strategy for investing ETH via UniswapV2
/// @author Bank of Chain Protocol Inc
contract ETHUniswapV2Strategy is ETHBaseStrategy, UniswapV2LiquidityActionsMixin {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IUniswapV2Pair public uniswapV2Pair;

    /// @notice Initialize this contract
    /// @param _vault The ETH vaults
    /// @param _name The name of strategy
    /// @param _pair One uniswapV2 pair address
    function initialize(address _vault,string memory _name,address _pair) external initializer {
        uniswapV2Pair = IUniswapV2Pair(_pair);
        address[] memory _wants = new address[](2);
        _wants[0] = uniswapV2Pair.token0();
        _wants[1] = uniswapV2Pair.token1();
        _initialize(_vault, uint16(ProtocolEnum.UniswapV2), _name,_wants);
        _initializeUniswapV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    /// @inheritdoc ETHBaseStrategy
    function getVersion() external pure virtual override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc ETHBaseStrategy
    function getWantsInfo() external view virtual override returns (address[] memory _assets, uint256[] memory _ratios) {
        (uint112 _reserve0, uint112 _reserve1, ) = uniswapV2Pair.getReserves();
        _assets = wants;
        _ratios = new uint256[](2);
        _ratios[0] = _reserve0;
        _ratios[1] = _reserve1;
    }

    /// @inheritdoc ETHBaseStrategy
    function getOutputsInfo() external view virtual override returns (OutputInfo[] memory _outputsInfo){
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
        (uint112 _reserve0, uint112 _reserve1, ) = uniswapV2Pair.getReserves();
        uint256 _totalSupply = uniswapV2Pair.totalSupply();
        uint256 _lpAmount = balanceOfToken(address(uniswapV2Pair));
        _tokens = wants;
        _amounts = new uint256[](2);
        _amounts[0] = (_lpAmount * _reserve0) / _totalSupply + balanceOfToken(_tokens[0]);
        _amounts[1] = (_lpAmount * _reserve1) / _totalSupply + balanceOfToken(_tokens[1]);
    }

    /// @notice Return The value in ETH of all ``uniswapV2Pair``'s total LP
    function lpValueInEth() internal view returns (uint256 _lpValue) {
        uint256 _totalSupply = uniswapV2Pair.totalSupply();
        (uint112 _reserve0, uint112 _reserve1, ) = uniswapV2Pair.getReserves();
        uint256 _lpDecimalUnit = 1e18;
        uint256 _part0 = (uint256(_reserve0) * (_lpDecimalUnit)) / _totalSupply;
        uint256 _part1 = (uint256(_reserve1) * (_lpDecimalUnit)) / _totalSupply;
        uint256 _partValue0 = priceOracleConsumer.valueInEth(wants[0], _part0);
        uint256 _partValue1 = priceOracleConsumer.valueInEth(wants[1], _part1);
        _lpValue = _partValue0 + _partValue1;
    }

    /// @inheritdoc ETHBaseStrategy
    function get3rdPoolAssets() external view virtual override returns (uint256) {
        
        uint256 _totalSupply = uniswapV2Pair.totalSupply();
        uint256 _lpValue = lpValueInEth();

        return (_totalSupply * _lpValue) / 1e18;
    }

    /// @inheritdoc ETHBaseStrategy
    function depositTo3rdPool(address[] memory _assets, uint256[] memory _amounts) internal virtual override {
        __uniswapV2Lend(address(this), _assets[0], _assets[1], _amounts[0], _amounts[1], 0, 0);
    }

    /// @inheritdoc ETHBaseStrategy
    function withdrawFrom3rdPool(uint256 _withdrawShares, uint256 _totalShares,uint256 _outputCode) internal virtual override {
        uint256 _withdrawAmount = (balanceOfToken(address(uniswapV2Pair)) * _withdrawShares) / _totalShares;
        if (_withdrawAmount > 0) {
            __uniswapV2Redeem(address(this), address(uniswapV2Pair), _withdrawAmount, wants[0], wants[1], 0, 0);
        }
    }

}
