const Utils = require("./assert-utils.js");
const {
    logPercent
} = require('./log-utils');
const BigNumber = require('bignumber.js');
const {
    AVERAGE_BLOCK_TIME
} = require('../config/chain-config.js');

/**
 * simulate minting block
 */
async function advanceBlock(days) {
    await advanceBlockV2(days);
    // for (let i = 1; i <= days; i++) {
    //     console.log("day: ", i);
    //     for (let hour = 1; hour <= 24; hour++) {
    //         logPercent(hour * 100 / 24);
    //         let blocksPerHour = 1800;
    //         await Utils.advanceNBlock(blocksPerHour);
    //     }
    // }
}

async function advanceBlockV2(days) {
    // calculate the amount of blocks
    const blockPerDay = parseInt(days * 24 * 60 * 60/AVERAGE_BLOCK_TIME);
    let beforeBlock = await hre.network.provider.send("eth_getBlockByNumber", ["latest", false]);
    console.log('before mine block:%s, timestamp:%s', new BigNumber(beforeBlock.number).toFixed(), new BigNumber(beforeBlock.timestamp).toFixed());
    // `hardhat_mine` accepts two parameters, both of which are optional.
    // The first parameter is the number of blocks to mine, and defaults to 1.
    // The second parameter is the interval between the timestamps of each block, _in seconds_, and it also defaults to 1. (The interval is applied only to blocks mined in the given method invocation, not to blocks mined afterwards.)
    // the arguments should be hex
    // for example,
    // if the first arg is 0x3e8, it means that mints 1_000 blocks
    // on top of that, if the second arg is 0x3c, it means that passed 60_000s
    await hre.network.provider.send("hardhat_mine", [
        '0x' + blockPerDay.toString(16),
        '0x' + AVERAGE_BLOCK_TIME.toString(16)
    ]);
    let afterBlock = await hre.network.provider.send("eth_getBlockByNumber", ["latest", false]);
    console.log('after mine block:%s, timestamp:%s', new BigNumber(afterBlock.number).toFixed(), new BigNumber(afterBlock.timestamp).toFixed());
    // await modifier();
}

async function advanceBlockOfHours(hours) {
    await advanceBlockOfHoursV2(hours);
    // for (let hour = 1; hour <= hours; hour++) {
    //     console.log("hours: ", hour);
    //     logPercent(hour * 100 / hours);
    //     let blocksPerHour = 211;
    //     await Utils.advanceNBlock(blocksPerHour);
    // }
}

async function advanceBlockOfHoursV2(hours) {
    // calculate the amount of blocks
    const blockPerHour = hours * 60 * 60 / AVERAGE_BLOCK_TIME;
    let beforeBlock = await hre.network.provider.send("eth_getBlockByNumber", ["latest", false]);
    console.log('before mine block:%s, timestamp:%s', new BigNumber(beforeBlock.number).toFixed(), new BigNumber(beforeBlock.timestamp).toFixed());
    // `hardhat_mine` accepts two parameters, both of which are optional.
    // The first parameter is the number of blocks to mine, and defaults to 1.
    // The second parameter is the interval between the timestamps of each block, _in seconds_, and it also defaults to 1. (The interval is applied only to blocks mined in the given method invocation, not to blocks mined afterwards.)
    // the arguments should be hex
    // for example,
    // if the first arg is 0x3e8, it means that mints 1_000 blocks
    // on top of that, if the second arg is 0x3c, it means that passed 60_000s
    await hre.network.provider.send("hardhat_mine", [
        '0x' + blockPerHour.toString(16),
        '0x' + AVERAGE_BLOCK_TIME.toString(16)
    ]);
    let afterBlock = await hre.network.provider.send("eth_getBlockByNumber", ["latest", false]);
    console.log('after mine block:%s, timestamp:%s', new BigNumber(afterBlock.number).toFixed(), new BigNumber(afterBlock.timestamp).toFixed());
}



async function closestBlockAfterTimestamp(timestamp) {
    let height = await ethers.provider.getBlockNumber();
    let lo = 0;
    let hi = height;
    while (hi - lo > 1) {
        let mid = lo + Math.floor((hi - lo) / 2);
        if ((await getBlock(mid)).timestamp > timestamp) {
            hi = mid;
        } else {
            lo = mid;
        }
    }
    if (hi != height) {
        return hi;
    } else {
        return 0;
    }
}

function getDaysAgoTimestamp(blockTimestamp, daysAgo) {
    //let nowMs = new Date(new Date().toLocaleDateString()).getTime()/1000;
    return blockTimestamp - 60 * 60 * 24 * daysAgo;
}

async function getLatestBlock() {
    const height = await ethers.provider.getBlockNumber();
    return (await ethers.provider.getBlock(height));
}

async function getBlock(height) {
    return await ethers.provider.getBlock(height);
}

module.exports = {
    advanceBlock,
    advanceBlockV2,
    advanceBlockOfHours,
    advanceBlockOfHoursV2,
    closestBlockAfterTimestamp,
    getDaysAgoTimestamp,
    getLatestBlock,
    getBlock,
}