const uniswapStrategies = [
//    {
//        name: "UniswapV2StEthWEthStrategy",
//        contract: "ETHUniswapV2Strategy",
//        profitLimitRatio: 100,
//        lossLimitRatio: 100,
//        addToVault: true,
//        customParams: [
//            "0x4028DAAC072e492d34a3Afdbef0ba7e35D8b55C4",//pair
//        ]
//    },
//    {
//        name: "UniswapV3RethEth3000Strategy",
//        contract: "ETHUniswapV3Strategy",
//        profitLimitRatio: 100,
//        lossLimitRatio: 100,
//        addToVault: true,
//        customParams: [
//            "0xf0E02Cf61b31260fd5AE527d58Be16312BDA59b1",
//            60,
//            60,
//            41400,
//            0,
//            100,
//            60,
//            60
//        ]
//    },
    {
        name: "UniswapV3EthUsdc500Strategy",
        contract: "ETHUniswapV3Strategy",
        profitLimitRatio: 1000000,
        lossLimitRatio: 1000000,
        addToVault: true,
        customParams: [
            "0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640",
            3600,
            1200,
            41400,
            0,
            100,
            60,
            60
        ]
    },
//    {
//        name: "UniswapV3EthUsdt500Strategy",
//        contract: "ETHUniswapV3Strategy",
//        profitLimitRatio: 1000000,
//        lossLimitRatio: 1000000,
//        addToVault: true,
//        customParams: [
//            "0x11b815efB8f581194ae79006d24E0d814B7697F6",
//            3600,
//            1200,
//            41400,
//            0,
//            100,
//            60,
//            60
//        ]
//    },
];

module.exports = {
    uniswapStrategies
};
