const checker = require('../strategy-checker');
// const {topUpBalByAddress} = require('../../../utils/top-up-utils');
// const IEREC20Mint = artifacts.require('IEREC20Mint');

describe('【AuraAave3PoolStrategy Strategy Checker】', function() {
    checker.check('AuraAave3PoolStrategy');
});