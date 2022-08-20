// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../external/cream/IPriceOracle.sol';

contract MockPriceOracle is IPriceOracle {

    mapping (address => uint) priceMap;
    address constant originPriceOracleAddr = 0xE4e9F6cfe8aC8C75A3dBeF809dbe4fc40e6FDc4b;

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

    function setUnderlyingPrice(address cToken,uint256 price) external {
        priceMap[cToken] = price;
    }

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address cToken) external override view returns (uint){
        return priceMap[cToken];
    }
}