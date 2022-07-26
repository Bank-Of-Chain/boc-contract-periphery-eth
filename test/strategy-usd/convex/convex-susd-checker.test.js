// npx hardhat test test\strategy-usd\convex\convex-susd-checker.test.js
const checker = require('../strategy-checker');

describe('【ConvexSusdStrategy Strategy Checker】', function() {
    checker.check('ConvexSusdStrategy');
});