// npx hardhat test test\strategy-usd\convex\convex-saave-checker.test.js
const checker = require('../strategy-checker');

describe('【ConvexSaaveStrategy Strategy Checker】', function() {
    checker.check('ConvexSaaveStrategy');
});