const checker = require('../../strategy-checker');
const {
    modifier
} = require('./synthetix-modifier.js');
const {
    advanceBlockOfHours
} = require('./../../../../utils/block-utils');

describe('【ConvexIronBankGbpStrategy Strategy Checker】', function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    checker.check('ConvexIBUsdtGbpStrategy', async function () {
        await modifier();
    }, {
        investWithSynthForex: async function (strategy, keeper) {
            // A delay of 6 minutes or more is required before continuing the reinjection operation
            await advanceBlockOfHours(1);
            await strategy.investWithSynthForex({
                from: keeper
            });
        }
    });
});