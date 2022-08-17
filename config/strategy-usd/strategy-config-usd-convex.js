const convexStrategies = [
    //IronBank-USDT
    {
        name: "ConvexIBUsdtAudStrategy",
        contract: "ConvexIBUsdtStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x86BBD9ac8B9B44C95FFc6BAAe58E25033B7548AA",//borrowCToken
            "0xb1Fae59F23CaCe4949Ae734E63E42168aDb0CcB3",//rewardPool
            "0x5b692073F141C31384faE55856CfB6CBfFE91E60" //usdc-ibforex pool
        ]
    },
    {
        name: "ConvexIBUsdtChfStrategy",
        contract: "ConvexIBUsdtStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x1b3E95E8ECF7A7caB6c4De1b344F94865aBD12d5",//borrowCToken
            "0xa5A5905efc55B05059eE247d5CaC6DD6791Cfc33",//rewardPool
            "0x6Df0D77F0496CE44e72D695943950D8641fcA5Cf" //usdc-ibforex pool
        ]
    },
    {
        name: "ConvexIBUsdtEurStrategy",
        contract: "ConvexIBUsdtStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x00e5c0774A5F065c285068170b20393925C84BF3",//borrowCToken
            "0xCd0559ADb6fAa2fc83aB21Cf4497c3b9b45bB29f",//rewardPool
            "0x1570af3dF649Fc74872c5B8F280A162a3bdD4EB6" //usdc-ibforex pool
        ]
    },
    {
        name: "ConvexIBUsdtGbpStrategy",
        contract: "ConvexIBUsdtStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xecaB2C76f1A8359A06fAB5fA0CEea51280A97eCF",//borrowCToken
            "0x51a16DA36c79E28dD3C8c0c19214D8aF413984Aa",//rewardPool
            "0xAcCe4Fe9Ce2A6FE9af83e7CF321a3fF7675e0AB6" //usdc-ibforex pool
        ]
    },
    {
        name: "ConvexIBUsdtJpyStrategy",
        contract: "ConvexIBUsdtStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x215F34af6557A6598DbdA9aa11cc556F5AE264B1",//borrowCToken
            "0xbA8fE590498ed24D330Bb925E69913b1Ac35a81E",//rewardPool
            "0xEB0265938c1190Ab4E3E1f6583bC956dF47C0F93" //usdc-ibforex pool
        ]
    },
    {
        name: "ConvexIBUsdtKrwStrategy",
        contract: "ConvexIBUsdtStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x3c9f5385c288cE438Ed55620938A4B967c080101",//borrowCToken
            "0x8F18C0AF0d7d511E8Bdc6B3c64926B04EDfE4892",//rewardPool
            "0xef04f337fCB2ea220B6e8dB5eDbE2D774837581c" //usdc-ibforex pool
        ]
    },
    //IronBank-USDC
    {
        name: "ConvexIBUsdcAudStrategy",
        contract: "ConvexIBUsdcStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x86BBD9ac8B9B44C95FFc6BAAe58E25033B7548AA",//borrowCToken
            "0x5b692073F141C31384faE55856CfB6CBfFE91E60",//curvePool
            "0xbAFC4FAeB733C18411886A04679F11877D8629b1",//rewardPool
            84
        ]
    },
    {
        name: "ConvexIBUsdcChfStrategy",
        contract: "ConvexIBUsdcStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x1b3E95E8ECF7A7caB6c4De1b344F94865aBD12d5",//borrowCToken
            "0x6Df0D77F0496CE44e72D695943950D8641fcA5Cf",//curvePool
            "0x9BEc26bDd9702F4e0e4de853dd65Ec75F90b1F2e",//rewardPool
            85
        ]
    },
    {
        name: "ConvexIBUsdcEurStrategy",
        contract: "ConvexIBUsdcStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x00e5c0774A5F065c285068170b20393925C84BF3",//borrowCToken
            "0x1570af3dF649Fc74872c5B8F280A162a3bdD4EB6",//curvePool
            "0xAab7202D93B5633eB7FB3b80873C817B240F6F44",//rewardPool
            86
        ]
    },
    {
        name: "ConvexIBUsdcGbpStrategy",
        contract: "ConvexIBUsdcStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0xecaB2C76f1A8359A06fAB5fA0CEea51280A97eCF",//borrowCToken
            "0xAcCe4Fe9Ce2A6FE9af83e7CF321a3fF7675e0AB6",//curvePool
            "0x8C87E32000ADD1a7D7D69a1AE180C415AF769361",//rewardPool
            87
        ]
    },
    {
        name: "ConvexIBUsdcJpyStrategy",
        contract: "ConvexIBUsdcStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x215F34af6557A6598DbdA9aa11cc556F5AE264B1",//borrowCToken
            "0xEB0265938c1190Ab4E3E1f6583bC956dF47C0F93",//curvePool
            "0x58563C872c791196d0eA17c4E53e77fa1d381D4c",//rewardPool
            88
        ]
    },
    {
        name: "ConvexIBUsdcKrwStrategy",
        contract: "ConvexIBUsdcStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x3c9f5385c288cE438Ed55620938A4B967c080101",//borrowCToken
            "0xef04f337fCB2ea220B6e8dB5eDbE2D774837581c",//curvePool
            "0x1900249c7a90D27b246032792004FF0E092Ac2cE",//rewardPool
            89
        ]
    },
    // Meta pool
    {
        name: "ConvexMetaBusdStrategy",
        contract: "ConvexMetaPoolStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x4Fabb145d64652a948d72533023f6E7A623C7C53",//pairToken
            "0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a",//curvePool
            "0xbD223812d360C9587921292D0644D18aDb6a2ad0",//rewardPool
        ]
    },
    {
        name: "ConvexMetaGusdStrategy",
        contract: "ConvexMetaPoolStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd",//pairToken
            "0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956",//curvePool
            "0x7A7bBf95C44b144979360C3300B54A7D34b44985",//rewardPool
        ]
    },
    {
        name: "ConvexMetaLusdStrategy",
        contract: "ConvexMetaPoolStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0",//pairToken
            "0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA",//curvePool
            "0x2ad92A7aE036a038ff02B96c88de868ddf3f8190",//rewardPool
        ]
    },
    // {
    //     name: "ConvexMetaMimStrategy",
    //     contract: "ConvexMetaPoolStrategy",
    //     profitLimitRatio: 100,
    //     lossLimitRatio: 100,
    //     addToVault: true,
    //     customParams: [
    //         "0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3",//pairToken
    //         "0x5a6A4D54456819380173272A5E8E9B9904BdF41B",//curvePool
    //         "0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771",//rewardPool
    //     ]
    // },
    {
        name: "ConvexMetaTusdStrategy",
        contract: "ConvexMetaPoolStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x0000000000085d4780B73119b644AE5ecd22b376",//pairToken
            "0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1",//curvePool
            "0x308b48F037AAa75406426dACFACA864ebd88eDbA",//rewardPool
        ]
    },
    {
        name: "ConvexMetaUsdpStrategy",
        contract: "ConvexMetaPoolStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
            "0x8E870D67F660D95d5be530380D0eC0bd388289E1",//pairToken
            "0xc270b3B858c335B6BA5D5b10e2Da8a09976005ad",//curvePool
            "0x500E169c15961DE8798Edb52e0f88a8662d30EC5",//rewardPool
        ]
    },
    // Others
    {
        name: "Convex3CrvStrategy",
        contract: "Convex3CrvStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    {
        name: "ConvexAaveStrategy",
        contract: "ConvexAaveStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    {
        name: "ConvexCompoundStrategy",
        contract: "ConvexCompoundStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    {
        name: "ConvexPaxStrategy",
        contract: "ConvexPaxStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    {
        name: "ConvexSaaveStrategy",
        contract: "ConvexSaaveStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    {
        name: "ConvexSusdStrategy",
        contract: "ConvexSusdStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    {
        name: "ConvexUsdtStrategy",
        contract: "ConvexUsdtStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    }
];

module.exports = {
    convexStrategies
};
