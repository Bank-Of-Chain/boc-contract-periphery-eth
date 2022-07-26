const fs = require('fs');
const {
	utils
} = require('ethers');

const {
	ethers,
	upgrades
} = require('hardhat');

const deployProxy = async (contractName, _args = [], overrides = {}, libraries = {}) => {
	console.log(` 🛰  Deploying as Proxy: ${contractName}`);

	const contractArgs = _args || [];
	const contractArtifacts = await ethers.getContractFactory(contractName, {
		libraries,
	});
	const deployed = await upgrades.deployProxy(contractArtifacts, contractArgs, overrides);
	console.log(`${contractName} deploying, address=`, deployed.address);
	fs.writeFileSync(`artifacts/${contractName}.address`, deployed.address);
	return deployed;
};

const deploy = async (contractName, _args = [], overrides = {}, libraries = {}) => {
	console.log(` 🛰  Deploying: ${contractName}`);
	
	const contractArgs = _args || [];
	const contractArtifacts = await ethers.getContractFactory(contractName, {
		libraries,
	});
	const deployed = await contractArtifacts.deploy(...contractArgs, overrides);
	const encoded = abiEncodeArgs(deployed, contractArgs);
	console.log(`${contractName} deploying, address=`, deployed.address);
	fs.writeFileSync(`artifacts/${contractName}.address`, deployed.address);

	if (!encoded || encoded.length <= 2) return deployed;
	fs.writeFileSync(`artifacts/${contractName}.args`, encoded.slice(2));

	return deployed;
};

const abiEncodeArgs = (deployed, contractArgs) => {
	// not writing abi encoded args if this does not pass
	if (!contractArgs || !deployed || !deployed['interface'] || !deployed['interface']['deploy']) {
		return '';
	}
	const encoded = utils.defaultAbiCoder.encode(deployed.interface.deploy.inputs, contractArgs);
	return encoded;
};

module.exports = {
	abiEncodeArgs,
	deploy,
	deployProxy,
};