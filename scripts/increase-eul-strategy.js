const {default: BigNumber} = require("bignumber.js");
const topUp = require('../utils/top-up-utils');
const MFC = require('../config/mainnet-fork-test-config');
const {ethers} = require("hardhat");
const EulerRevolvingLoanStrategy = hre.artifacts.require('ETHEulerRevolvingLoanStrategy');
const ERC20 = hre.artifacts.require('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
const merkleTree = require('../utils/merkle-tree');
const eulerUtils = require('../utils/euler-utils');
const {balance, send} = require("@openzeppelin/test-helpers");

const main = async () => {
    //need url strategy address
    const strategyAddress = '0x8f119cd256a0FfFeed643E830ADCD9767a1d517F';
    const strategy = await EulerRevolvingLoanStrategy.at(strategyAddress);
    const eulClaimAccount = '0xf2E12342bf778cF57d44418F949c876c2e5DaeBA';
    const eulContract = await ERC20.at('0xd9fcd98c322942075a5c3860693e9f4f03aae07b');
    console.log("before claim",(await eulContract.balanceOf(eulClaimAccount)).toString());

    const distFile = './test/merkle-dist.json.gz';
    let distribution = eulerUtils.loadMerkleDistFile(distFile);

    let items = distribution.values.map(v => { return {
        account: v[0],
        token: v[1],
        claimable: ethers.BigNumber.from(v[2]),
    }});

    let proof = merkleTree.proof(items, eulClaimAccount, eulerUtils.EulTokenAddr);

    await strategy.claim(eulClaimAccount,eulerUtils.EulTokenAddr,proof.item.claimable.toString(),proof.witnesses,'0x0000000000000000000000000000000000000000');
    const claimAmount = await eulContract.balanceOf(eulClaimAccount);
    console.log("after claim",claimAmount.toString());

    // mock owner
    await ethers.getImpersonatedSigner(eulClaimAccount);
    const accounts = await ethers.getSigners();
    await send.ether(accounts[0].address, eulClaimAccount, 10 * 10 ** 18);
    await eulContract.transfer(strategy.address, claimAmount.toString(), {
        from: eulClaimAccount,
    });
    
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });