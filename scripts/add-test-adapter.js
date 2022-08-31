const TestAdapter = hre.artifacts.require('contracts/exchanges/adapters/TestAdapter.sol:MyTestAdapter');

const main = async () => {
    const testAdapter = await TestAdapter.new('0x572316aC11CB4bc5daf6BDae68f43EA3CCE3aE0e');
    console.log(testAdapter.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
