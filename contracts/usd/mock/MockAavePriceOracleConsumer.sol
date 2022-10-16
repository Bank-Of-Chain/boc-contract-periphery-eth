// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../external/aave/IPriceOracleGetter.sol";

/// @title MockAavePriceOracleConsumer
/// @notice The mock contract of Aave's PriceOracleConsumer contract
contract MockAavePriceOracleConsumer is IPriceOracleGetter {

    mapping(address => uint) private priceMap;
    address private constant originPriceOracleConsumerAddr = 0xA50ba011c48153De246E5192C8f9258A2ba79Ca9;

    constructor(){
        IPriceOracleGetter originPriceOracle = IPriceOracleGetter(originPriceOracleConsumerAddr);
        // init asset price
        //USDC
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        priceMap[USDC] = originPriceOracle.getAssetPrice(USDC);
        //USDT
        address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        priceMap[USDT] = originPriceOracle.getAssetPrice(USDT);
        //DAI
        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        priceMap[DAI] = originPriceOracle.getAssetPrice(DAI);
        //WETH
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        priceMap[WETH] = originPriceOracle.getAssetPrice(WETH);
        //stETH
        address ST_ETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        priceMap[ST_ETH] = originPriceOracle.getAssetPrice(ST_ETH);
        //ETH
        address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        priceMap[ETH] = originPriceOracle.getAssetPrice(WETH);
    }

    /// @notice Sets the underlying _price of a `_asset` asset
    /// @param _asset The `_asset` to get the underlying `_price` of
    /// @param _price The new value of ``_asset``'s price
    function setAssetPrice(address _asset,uint256 _price) external {
        priceMap[_asset] = _price;
    }

    /// @notice Gets the price of a `_asset` asset
    /// @param _asset It is this `_asset` that gets it the price of
    /// @return the price of a `_asset` asset (scaled by 1e18).
    ///  Zero means the `_price` is unavailable.
    function getAssetPrice(address _asset) public override view returns (uint){
        return priceMap[_asset];
    }

    /// @notice Gets a list of prices from a list of assets addresses
    /// @param _assets The list of assets addresses
    function getAssetsPrices(address[] calldata _assets) external override view returns (uint256[] memory){
        uint256 _assetsLength = _assets.length;
        uint256[] memory _prices = new uint256[](_assetsLength);
        for (uint256 i = 0; i < _assetsLength; i++){
            _prices[i] = getAssetPrice(_assets[i]);
        }
        return _prices;
    }
}