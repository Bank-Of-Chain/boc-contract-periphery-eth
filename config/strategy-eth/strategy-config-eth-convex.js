const convexStrategies = [
    
    {
        name: "ConvexrETHwstETHStrategy",
        contract: "ConvexrETHwstETHStrategy",
        profitLimitRatio: 100,
        lossLimitRatio: 100,
        addToVault: true,
        customParams: [
        ]
    },
    // {
    //     name: "ConvexSETHStrategy",
    //     contract: "ConvexSETHStrategy",
    //     profitLimitRatio: 100,
    //     lossLimitRatio: 100,
    //     addToVault: true,
    //     customParams: [
    //     ]
    // },
    {
        name: "ConvexStETHStrategy",
        contract: "ConvexStETHStrategy",
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
