const checker = require('../../strategy-checker');

const {
    advanceBlockOfHours
} = require('../../../../utils/block-utils');

describe('【ConvexIBUSDCEurStrategy Strategy Checker】', function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    checker.check('ConvexIBUsdcEurStrategy', async function () {
        // await modifier();
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