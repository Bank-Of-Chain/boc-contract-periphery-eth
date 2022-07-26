const checker = require('../../strategy-checker');

const {
    advanceBlockOfHours
} = require('../../../../utils/block-utils');
const ConvexIBUSDCBaseStrategy = hre.artifacts.require('ConvexIBUSDCBaseStrategy');

describe('【ConvexIBUSDCAudStrategy Strategy Checker】', function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    checker.check('ConvexIBUSDCAudStrategy', async function (strategyAddr,keeper) {
        // await modifier();
        const strategy = await ConvexIBUSDCBaseStrategy.at(strategyAddr);
        const debtRateBeforeDecrease = await strategy.debtRate();
        const collateralRateBeforeDecrease = await strategy.collateralRate();
        await strategy.rebalance({from:keeper});
        const debtRateAfterDecrease = await strategy.debtRate();
        const collateralRateAfterDecrease = await strategy.collateralRate();
        console.log('debtRateBeforeDecrease:%s,debtsAfterDecrease:%s',debtRateBeforeDecrease,debtRateAfterDecrease);
        console.log('collateralRateBeforeDecrease:%s,collateralRateAfterDecrease:%d',collateralRateBeforeDecrease,collateralRateAfterDecrease);
        
    }, {
        // investWithSynthForex: async function (strategy, keeper) {
        //     // A delay of 6 minutes or more is required before continuing the reinjection operation
        //     await advanceBlockOfHours(1);
        //     await strategy.investWithSynthForex({
        //         from: keeper
        //     });
        // }
    });
});