const checker = require('../strategy-checker');
const {topUpBalByAddress} = require('../../../utils/top-up-utils');
// const IEREC20Mint = artifacts.require('IEREC20Mint');

describe('【Balancer3CrvStrategy Strategy Checker】', function() {
    checker.check('Balancer3CrvStrategy');
});