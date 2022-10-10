const checker = require('../strategy-checker');
// const {topUpBalByAddress} = require('../../../utils/top-up-utils');
// const IEREC20Mint = artifacts.require('IEREC20Mint');

describe('【AaveUSDCStrategy Strategy Checker】', function() {
    checker.check('AaveUSDCStrategy',null,null,0);
});