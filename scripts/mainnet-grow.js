const {
    advanceBlockV2
} = require('../utils/block-utils');

const main = async () => {
    await advanceBlockV2(1);

};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });