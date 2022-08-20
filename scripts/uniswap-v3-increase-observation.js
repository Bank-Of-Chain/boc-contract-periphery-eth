const IUniswapV3Pool = hre.artifacts.require('@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol:IUniswapV3Pool');

const main = async () => {
    const network = hre.network.name;
    console.log('\n\n 📡 uniswapv3 increaseObservationCardinalityNext ... At %s Network \n', network);

    const uniswapV3PoolContract = await IUniswapV3Pool.at('0xa9ffb27d36901F87f1D0F20773f7072e38C5bfbA');
    let slot = await uniswapV3PoolContract.slot0();
    console.log('before increaseObservationCardinalityNext observationCardinalityNext: %d', slot.observationCardinalityNext);

    await uniswapV3PoolContract.increaseObservationCardinalityNext(180);

    slot = await uniswapV3PoolContract.slot0();
    console.log('after increaseObservationCardinalityNext observationCardinalityNext: %d', slot.observationCardinalityNext);

    console.log('increaseObservationCardinalityNext finish!!!');
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
