// npx hardhat test ./test/strategy/convex/convex-stETH-strategy-checker.js
const checker = require('../strategy-checker');
describe('【ConvexStETHStrategy Strategy Checker】', function() {
    checker.check('ConvexStETHStrategy');
});
