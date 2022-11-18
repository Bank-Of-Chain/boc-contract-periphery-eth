const fs = require('fs');

const ethers = require('ethers');

const utils = require('./euler-utils');



let mode = process.argv[2];

if (mode === 'dump') {
    let file = process.argv[3];
    let outputFile = process.argv[4];

    let distribution = utils.loadMerkleDistFile(file);
    let output = render(distribution);
    fs.writeFileSync(outputFile, output);
} else if (mode === 'diff') {
    let file1 = process.argv[3];
    let file2 = process.argv[4];
    let outputFile = process.argv[5];

    let distribution1 = utils.loadMerkleDistFile(file1);
    let distribution2 = utils.loadMerkleDistFile(file2);

    let distributionDiff = diff(distribution1, distribution2);

    let output = render(distributionDiff);
    fs.writeFileSync(outputFile, output);
} else {
    throw Error(`unknown mode: ${mode}`);
}







function render(distribution) {
    let addrs = [];

    for (let v of distribution.values) {
        if (v[1] !== utils.EulTokenAddr) continue;
        addrs.push(v);
    }

    addrs.sort((a,b) => {
        let v1 = ethers.BigNumber.from(a[2]);
        let v2 = ethers.BigNumber.from(b[2]);

        if (v1.eq(v2)) return 0;
        else if (v1.lt(v2)) return 1;
        else return -1;
    });

    let total;

    if (distribution.mode === 'diff') {
        total = ethers.BigNumber.from(distribution.info2.totals[utils.EulTokenAddr]).sub(distribution.info1.totals[utils.EulTokenAddr]).toString();
    } else {
        total = distribution.info.totals[utils.EulTokenAddr];
    }

    let output = `## Merkle Drop Summary\n`;

    if (distribution.mode === 'diff') {
        output += `
* Block range: ${distribution.info1.lastBlock} - ${distribution.info2.lastBlock}
* Total: \`${ethers.utils.formatEther(total)} EUL\`
* Accounts: ${addrs.length}
`;
    } else {
        output += `
* Block: ${distribution.info.lastBlock}
* Root: \`${distribution.info.root}\`
* Total: \`${ethers.utils.formatEther(total)} EUL\`
* Accounts: ${addrs.length}
`;
    }

    output += `
| Address     | Amount    | Percent | Links |
| ----------- | --------- | ---- | ---- |
`;

    for (let a of addrs) {
        let percent = ethers.BigNumber.from(a[2]).mul(1e6).div(total).toNumber() / 1e6 * 100;
        let links = `[etherscan](https://etherscan.io/address/${a[0]}) [spy](https://app.euler.finance/account/0?spy=${a[0]})`;
        output += `| \`${a[0]}\` | \`${ethers.utils.formatEther(a[2])} EUL\` | \`${percent.toFixed(3)}%\` | ${links} |\n`;
    }

    return output;
}


function diff(d1, d2) {
    let o = {};

    o.mode = 'diff';
    o.info1 = d1.info;
    o.info2 = d2.info;
    o.values = [];

    let prevValues = {};

    for (let v of d1.values) {
        if (v[1] !== utils.EulTokenAddr) continue;
        prevValues[v[0]] = v[2];
    }

    for (let v of d2.values) {
        let prev = prevValues[v[0]];
        if (!prev) prev = '0';

        let delta = ethers.BigNumber.from(v[2]).sub(prev).toString();

        if (delta === '0') continue;

        o.values.push([
            v[0],
            utils.EulTokenAddr,
            delta,
        ]);
    }

    return o;
}