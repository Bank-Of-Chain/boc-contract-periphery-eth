const uniswapStrategies = [
    {
        name: "UniswapV3BusdUsdc500Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x00cEf0386Ed94d738c8f8A74E8BFd0376926d24C",
            10,
            10,
            41400,
            0,
            100,
            60,
            10
        ]
    },
    {
        name: "UniswapV3DaiUsdc100Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168",
            5,
            2,
            41400,
            0,
            100,
            60,
            1
        ]
    },
    {
        name: "UniswapV3DaiUsdc500Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6c6Bc977E13Df9b0de53b251522280BB72383700",
            10,
            10,
            41400,
            0,
            100,
            60,
            10
        ]
    },
    {
        name: "UniswapV3DaiUsdt500Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x6f48ECa74B38d2936B02ab603FF4e36A6C0E3A77",
            10,
            10,
            41400,
            0,
            100,
            60,
            10
        ]
    },
    {
        name: "UniswapV3GusdUsdc3000Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x93f267fD92B432BeBf4dA4E13B8615Bb8Eb2095C",
            60,
            60,
            41400,
            0,
            100,
            60,
            60
        ]
    },
    {
        name: "UniswapV3TusdUsdc100Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x39529E96c28807655B5856b3d342c6225111770e",
            5,
            2,
            41400,
            0,
            100,
            60,
            1
        ]
    },
    {
        name: "UniswapV3UsdcUsdt100Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x3416cF6C708Da44DB2624D63ea0AAef7113527C6",
            5,
            2,
            41400,
            0,
            100,
            60,
            1
        ]
    },
    {
        name: "UniswapV3UsdcUsdt500Strategy",
        contract: "UniswapV3Strategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf",
            0,
            10,
            41400,
            0,
            100,
            60,
            10
        ]
    },
];

module.exports = {
    uniswapStrategies
};
