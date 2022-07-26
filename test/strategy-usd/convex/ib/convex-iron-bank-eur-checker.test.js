const checker = require('../../strategy-checker');
const {
    modifier
} = require('./synthetix-modifier.js');
const {
    advanceBlockOfHours
} = require('./../../../../utils/block-utils');

describe('【ConvexIronBankEurStrategy Strategy Checker】', function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    checker.check('ConvexIronBankEurStrategy', async function () {
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