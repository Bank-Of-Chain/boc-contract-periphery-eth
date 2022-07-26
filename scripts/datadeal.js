const strategyArray =[
    "ConvexIronBankEurStrategy",
    "ConvexIronBankChfStrategy",
    "DForceLendUsdtStrategy",
    "ConvexBusdV2Strategy",
    "DodoDaiUsdtStrategy",
    "DodoUsdtUsdcStrategy",
    "DForceLendDaiStrategy",
    "ConvexLusdStrategy",
    "DForceLendUsdcStrategy",
    "ConvexBusdStrategy",
    "ConvexUsdpStrategy",
    "Balancer3CrvStrategy",
    "ConvexIronBankGbpStrategy",
    "ConvexIronBankKrwStrategy",
    "ConvexIronBankAudStrategy",
    "ConvexIronBankJpyStrategy",
    "YearnEarnUsdcStrategy",
    "YearnEarnTusdStrategy",
    "YearnEarnDaiStrategy",
    "YearnEarnUsdtStrategy",
    "YearnEarnBusdStrategy"
];

const strategiesList =[];
for(const strategy of strategyArray){
    strategiesList.push(
        {
            name: strategy,
            profitLimitRatio: 100,
            lossLimitRatio: 100,
            addToVault: true,
        })
}

console.log('-----------strategiesList---------')
console.log(JSON.stringify(strategiesList));
console.log('----------------------------------')