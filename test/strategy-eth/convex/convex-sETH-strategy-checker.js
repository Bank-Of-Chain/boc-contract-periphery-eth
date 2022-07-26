// npx hardhat test test\strategy\convex\convex-sETH-strategy-checker.js
const checker = require('../strategy-checker');
describe('【ConvexSETHStrategy Strategy Checker】', function() {
    checker.check('ConvexSETHStrategy');
});
