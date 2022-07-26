const BigNumber = require('bignumber.js');
const {
    time
} = require("@openzeppelin/test-helpers");

BigNumber.config({
    DECIMAL_PLACES: 0
});

async function advanceNBlock(n) {
    let startingBlock = await time.latestBlock();
    await time.increase(2 * Math.round(n));
    let endBlock = startingBlock.addn(n);
    await time.advanceBlockTo(endBlock);
}
async function waitHours(n) {
    await time.increase(n * 3600 + 1);
    let startingBlock = await time.latestBlock();
    await time.advanceBlockTo(startingBlock.addn(1));
}

async function waitTime(n) {
    await time.increase(n);
    let startingBlock = await time.latestBlock();
    await time.advanceBlockTo(startingBlock.addn(1));
}

function assertBNEq(a, b, message = '') {
    let _a = new BigNumber(a);
    let _b = new BigNumber(b);
    let msg = `${message}
  ${_a.toFixed()} != ${_b.toFixed()}`;
    assert.equal(_a.eq(_b), true, msg);
}

function assertApproxBNEq(a, b, c) {
    let _a = new BigNumber(a).div(c);
    let _b = new BigNumber(b).div(c);
    let msg = _a.toFixed() + " != " + _b.toFixed();
    assert.equal(_a.eq(_b), true, msg);
}

function assertBNGt(a, b) {
    let _a = new BigNumber(a);
    let _b = new BigNumber(b);
    let msg = _a.toFixed() + " is not greater than " + _b.toFixed();
    assert.equal(_a.gt(_b), true, msg);
}

function assertBNGte(a, b) {
    let _a = new BigNumber(a);
    let _b = new BigNumber(b);
    let msg = _a.toFixed() + " is not greater than " + _b.toFixed();
    assert.equal(_a.gte(_b), true, msg);
}

function assertNEqBN(a, b) {
    let _a = new BigNumber(a);
    let _b = new BigNumber(b);
    assert.equal(_a.eq(_b), false);
}

function assertBNBt(a, b, c) {
    let _a = new BigNumber(a);
    let _b = new BigNumber(b);
    let _c = new BigNumber(c);
    let msg = `${_a.toFixed()} <= ${_b.toFixed()} <= ${_c.toFixed()}`;
    assert.equal(_b.gte(_a), true, msg);
    assert.equal(_c.gte(_b), true, msg);
}

module.exports = {
    advanceNBlock,
    assertBNEq,
    assertApproxBNEq,
    assertBNGt,
    assertNEqBN,
    waitHours,
    waitTime,
    assertBNGte,
    assertBNBt
};