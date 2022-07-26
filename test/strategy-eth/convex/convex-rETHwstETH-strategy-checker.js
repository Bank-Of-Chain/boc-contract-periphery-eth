// npx hardhat test ./test/strategy/convex/convex-rETHwstETH-strategy-checker.js
const checker = require('../strategy-checker');
describe('【ConvexrETHwstETHStrategy Strategy Checker】', function() {
    checker.check('ConvexrETHwstETHStrategy');
});
