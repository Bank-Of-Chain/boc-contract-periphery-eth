const checker = require('../strategy-checker');
const { topUpBalByAddress } = require('../../../utils/top-up-utils');
describe('【AuraREthWEthStrategy Strategy Checker】', function () {
    checker.check('AuraREthWEthStrategy', async function (strategy) {
    }, null,null,1);
});