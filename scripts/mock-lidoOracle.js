const {ethers,} = require('hardhat');
const { send, balance} = require("@openzeppelin/test-helpers");
const { advanceBlockV2, advanceBlockOfHours} = require('../utils/block-utils');

const Lido = hre.artifacts.require("ILido");
const LidoOracle = hre.artifacts.require("ILidoOracle");
const WstETH = hre.artifacts.require("IWstETH");

// lido address
const lidoAddress = '0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84';
// lido oracle address
const lidoOracleAddress = '0x442af784A788A5bd6F42A01Ebe9F287a871243fb';
// wstETH address
const wstETHAddress = '0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0';

// lido holders
const holder01 = '0x9E9F792BA171D599FCce34f4398EB3298C1E1175';//140.0618
const holder02 = '0xb55a89d0ed2ae3267200ef216fe11c6f4ba52ebd';//141.5562

// 5 oraclers reporting // report times >= Quorum == 3
const oraclers = [
    '0x140Bd8FbDc884f48dA7cb1c09bE8A2fAdfea776E',
    //'0x1d0813bf088BE3047d827D98524fBf779Bc25F00',
    //'0x404335BcE530400a5814375E7Ec1FB55fAff3eA2',
    '0x946D3b081ed19173dC83Cd974fC69e1e760B7d78',
    '0x007DE4a5F7bc37E2F26c0cb2E8A95006EE9B89b5'
];

// the apr is 
async function reportOracle(passDays, increaseRate) {

    if(increaseRate > 100) {// per 1000, 100 => 10% //apr limit up 10% ,down 5%
        increaseRate = 100;
    }

    let apr = Math.floor(increaseRate/passDays);// per 1000, 100 => 10%

    // call reportBeacon
    const lido = await Lido.at(lidoAddress);
    const lidoOracle = await LidoOracle.at(lidoOracleAddress);
    const wstETH = await WstETH.at(wstETHAddress);

    //let laestBlockNum = await getLatestBlock()
    let lastEpochId = await lidoOracle.getLastCompletedEpochId();

    let beaconStat = await lido.getBeaconStat();
    let depositedValidators = beaconStat.depositedValidators.toNumber();//same value when test on fork
    console.log("depositedValidators is", beaconStat.depositedValidators.toNumber());
    let lastBeaconBalance = beaconStat.beaconBalance;

    //  newBeaconBalance = lastBeaconBalance *(1 + increaseRate/100/365)
    lastBeaconBalance = ethers.BigNumber.from(lastBeaconBalance.toString());
    let lastBeaconBalanceDiv1e9 = lastBeaconBalance.div(10**9);
    let newBeaconBalanceDiv1e9 = lastBeaconBalanceDiv1e9.mul(apr).div(1000).div(365).add(lastBeaconBalanceDiv1e9);
    let deltaOneday = newBeaconBalanceDiv1e9.sub(lastBeaconBalanceDiv1e9);
    console.log("deltaOneday is ",deltaOneday);
    newBeaconBalanceDiv1e9 = deltaOneday.mul(passDays).add(lastBeaconBalanceDiv1e9);
    console.log("lastBeaconBalanceDiv1e9.toString() is ", lastBeaconBalanceDiv1e9.toString());
    console.log("newBeaconBalanceDiv1e9.toString() is ", newBeaconBalanceDiv1e9.toString());
    
    for(const oracler of oraclers) {
        // mock oracler
        await ethers.getImpersonatedSigner(oracler);
        // transfer eth to oracler
        const accounts = await ethers.getSigners();
        const beforeBalance = await balance.current(oracler)
        if(beforeBalance.toString() < '10000000000000000000'){
            await send.ether(accounts[0].address, oracler, 10 * 10 ** 18)
        }
    }

    let bal01Before = await lido.balanceOf(holder01);
    let bal02Before = await lido.balanceOf(holder02);

    await advanceBlockV2(1);
    //await advanceBlockOfHours(22);
    let currentEpochId = await lidoOracle.getExpectedEpochId();
    let expectedEpochId = await lidoOracle.getExpectedEpochId();
    let inputEpochId =Math.max(currentEpochId,expectedEpochId);
    
    // need 3 oraclers report
    for (const acc of oraclers) {
        const receipt = await lidoOracle.reportBeacon(inputEpochId, newBeaconBalanceDiv1e9, depositedValidators , { from: acc })
    }

    let bal01After = await lido.balanceOf(holder01);
    let bal02After = await lido.balanceOf(holder02);

    console.log("before bal01",bal01Before.toString());
    console.log("after bal01",bal01After.toString());

    console.log("before bal02",bal02Before.toString());
    console.log("after bal02",bal02After.toString());
    
}

// async function main() {
//     let passDays = 1;
//     await advanceBlockV2(passDays);
//     await reportOracle(passDays,100);//per 1000, increaseRate is 10%, not apr

//     await advanceBlockV2(passDays);
//     await reportOracle(passDays,50);

//     passDays = 2;
//     await advanceBlockV2(passDays);
//     await reportOracle(passDays,80);

//     passDays = 3;
//     await advanceBlockV2(passDays);
//     await reportOracle(passDays,99);

//     passDays = 5;
//     await advanceBlockV2(passDays);
//     await reportOracle(passDays,200);

// }


// main()
//     .then(() => process.exit(0))
//     .catch(error => {
//         console.error(error);
//         process.exit(1);
//     });

module.exports = {
    reportOracle
}
