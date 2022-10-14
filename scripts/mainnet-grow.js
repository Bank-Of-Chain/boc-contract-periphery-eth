const {
    advanceBlockV2
} = require('../utils/block-utils');
const {reportOracle} = require('./mock-lidoOracle');

const main = async () => {
    await advanceBlockV2(1);// pass one day
    let aprX1000 = 100;// per 1000; apr <= 10%; 
    await reportOracle(1,aprX1000)

};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });