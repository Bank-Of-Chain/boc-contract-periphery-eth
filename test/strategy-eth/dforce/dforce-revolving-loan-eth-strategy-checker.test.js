const checker = require('../strategy-checker');
const { topUpBalByAddress } = require('../../../utils/top-up-utils');
describe('【DForceRevolvingLoanETHStrategy Strategy Checker】', function () {
    checker.check('DForceRevolvingLoanETHStrategy', async function (strategy) {
    }, null,null,1);
});