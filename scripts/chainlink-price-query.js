const {ethers} = require('hardhat');
const MFC_PRODUCTION = require('../config/mainnet-fork-config');

const main = async () => {
    const network = hre.network.name;
    const MFC = MFC_PRODUCTION

    const queryBlocks = [14763291, 14764786, 14785409, 'latest'];
    const aggregators = [MFC.CHAINLINK.aggregators.USDT_USD];
    const results = [];

    for (const aggregator of aggregators) {
        let aggregatorContract = await ethers.getContractAt('AggregatorV3Interface', aggregator.aggregator);
        let queryResults = [];
        for (const block of queryBlocks) {
            let latestRound = await aggregatorContract.latestRoundData({blockTag: block});
            queryResults.push({
                block,
                answer: latestRound.answer.toString()
            })
        }
        let result = {
            aggregator,
            queryResults
        }
        results.push(result);
    }
    console.log(JSON.stringify(results));
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });