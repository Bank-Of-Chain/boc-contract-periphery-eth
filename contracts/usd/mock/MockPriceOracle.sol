// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../external/cream/IPriceOracle.sol";

/// @title MockPriceOracle
/// @notice The mock contract of PriceOracle contract
contract MockPriceOracle is IPriceOracle {

    mapping(address => uint) private priceMap;
    address private constant originPriceOracleAddr = 0xE4e9F6cfe8aC8C75A3dBeF809dbe4fc40e6FDc4b;

    constructor(){
        IPriceOracle originPriceOracle = IPriceOracle(originPriceOracleAddr);
        //USDC
        address cUSDC = 0x76Eb2FE28b36B3ee97F3Adae0C69606eeDB2A37c;
        priceMap[cUSDC] = originPriceOracle.getUnderlyingPrice(cUSDC);
        //USDT
        address cUSDT = 0x48759F220ED983dB51fA7A8C0D2AAb8f3ce4166a;
        priceMap[cUSDT] = originPriceOracle.getUnderlyingPrice(cUSDT);
        //cAUD
        address cAUD = 0x86BBD9ac8B9B44C95FFc6BAAe58E25033B7548AA;
        priceMap[cAUD] = originPriceOracle.getUnderlyingPrice(cAUD);
        //cCHF
        address cCHF = 0x1b3E95E8ECF7A7caB6c4De1b344F94865aBD12d5;
        priceMap[cCHF] = originPriceOracle.getUnderlyingPrice(cCHF);
        //cEUR
        address cEUR = 0x00e5c0774A5F065c285068170b20393925C84BF3;
        priceMap[cEUR] = originPriceOracle.getUnderlyingPrice(cEUR);
        //cGBP
        address cGBP = 0xecaB2C76f1A8359A06fAB5fA0CEea51280A97eCF;
        priceMap[cGBP] = originPriceOracle.getUnderlyingPrice(cGBP);
        //cJPY
        address cJPY = 0x215F34af6557A6598DbdA9aa11cc556F5AE264B1;
        priceMap[cJPY] = originPriceOracle.getUnderlyingPrice(cJPY);
        //cKRW
        address cKRW = 0x3c9f5385c288cE438Ed55620938A4B967c080101;
        priceMap[cKRW] = originPriceOracle.getUnderlyingPrice(cKRW);
    }

    /// @notice Sets the underlying _price of a `_cToken` asset
    /// @param _cToken The `_cToken` to get the underlying `_price` of
    /// @param _price The new value of ``_cToken``'s price
    function setUnderlyingPrice(address _cToken,uint256 _price) external {
        priceMap[_cToken] = _price;
    }

    /// @notice Gets the price of a `_cToken` asset
    /// @param _cToken It is this `_cToken` that gets it the price of
    /// @return the price of a `_cToken` asset (scaled by 1e18).
    ///  Zero means the `_price` is unavailable.
    function getUnderlyingPrice(address _cToken) external override view returns (uint){
        return priceMap[_cToken];
    }
}