const {
    advanceBlockV2
} = require('../utils/block-utils');
const {reportOracle} = require('./mock-lidoOracle');

const main = async () => {
    // await advanceBlockV2(1);
    await reportOracle(1,60)

};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });