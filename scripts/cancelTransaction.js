const hre = require("hardhat");
const { ethers } = hre;
const gasPrice = ethers.utils.parseUnits('50', 'gwei');
const gasLimit = 10_000_000;
async function main() {
    // txHash to cancel
    const txHash = '0x1f9b0112f6aba317c0ec029859ee28475f978267c5bf8a59d5a676e899c4706b';
    const accounts = await ethers.getSigners();
    const sender = accounts[0];
    console.log(`sender address: ${sender.address}`);
    const tx = await ethers.provider.getTransaction(txHash);
    const nonce = await ethers.provider.getTransactionCount(sender.address);
    const CancelByNonce = true;
    console.log('tx:', tx);
    console.log('nonce:', nonce);
    const replacementRequest = {
        to: CancelByNonce ? sender.address : tx.to,
        from: CancelByNonce ?  sender.address : tx.from,
        nonce: CancelByNonce ? nonce : tx.nonce,
        value: 0,
        gasPrice,
        gasLimit
    };
    const replacementTx = await sender.sendTransaction(replacementRequest);
    console.log(`replacement txHash: ${replacementTx.hash}`);
    await replacementTx.wait(1);
    console.log('Done');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });