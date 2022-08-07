// npx hardhat test test\strategy-usd\convex\convex-gusd-checker.test.js
const checker = require('../../strategy-checker');

describe('【ConvexMetaGusdStrategy Strategy Checker】', function() {
    checker.check('ConvexMetaGusdStrategy');
});