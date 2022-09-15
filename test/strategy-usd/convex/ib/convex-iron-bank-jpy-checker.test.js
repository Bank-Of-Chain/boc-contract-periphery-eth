const checker = require('../../strategy-checker');
const {
    modifier
} = require('../../../../scripts/synthetix_modifier');

const {
    advanceBlockOfHours
} = require('./../../../../utils/block-utils');

describe('【ConvexIronBankJpyStrategy Strategy Checker】', function () {
    // eslint-disable-next-line mocha/no-setup-in-describe
    checker.check('ConvexIBUsdtJpyStrategy', async function (strategy, keeper) {
        await modifier();
    },function(){},async function (strategy, keeper) {
        await advanceBlockOfHours(1);
        await strategy.investWithSynthForex({
            from: keeper
        });
    });
});