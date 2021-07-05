/******************************************************************************
**	@Author:				Thomas Bouder <Tbouder>
**	@Email:					Tbouder@protonmail.com
**	@Date:					Thursday June 17th 2021
**	@Filename:				2_medicis.js
******************************************************************************/

const ethers = require('ethers');
const Mappings = artifacts.require("Mappings");
const Medicis = artifacts.require("Medicis");
const Donatori = artifacts.require("Donatori");
const Beneficiari = artifacts.require("Beneficiari");

const	VERSION = 'USDC';
const	DEPLOYER = '0x72bddca8b8fee4ca061adab9833b03f400586e65a73689f6852ce8d7d52ffa3f';
const	USDC_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const	WBTC_ADDRESS = '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599'

const	ABI_MEDICIS = [
	'function setDonatori(address _donatori) public',
	'function setBeneficiari(address _beneficiari) public',
];

module.exports = async function (deployer, _, accounts) {
	if (VERSION === 'USDC') {
		/**************************************************************************
		**	Deploying Medicis
		**************************************************************************/
		await	deployer.deploy(Medicis, USDC_ADDRESS, accounts[0], accounts[0]);
		const	medicisAddress = (await Medicis.deployed()).address;

		await	deployer.deploy(Mappings);
		await	deployer.link(Mappings, Donatori);
		await	deployer.deploy(Donatori, medicisAddress,
			['#3f3f3f', '#4b58d4', '#bbebf2', '#00b4d8', '#0077b6', '#85ebf9'],
			[100 * 100000,
			1000 * 100000,
			10000 * 100000,
			50000 * 100000,
			100000 * 100000]
		);
		await	deployer.link(Mappings, Beneficiari);
		await	deployer.deploy(Beneficiari, medicisAddress, 6);

		/**************************************************************************
		**	Setup the signer
		**************************************************************************/
		const	provider = ethers.getDefaultProvider('http://localhost:8545');
		const   signer = new ethers.Wallet(DEPLOYER, provider)
		const	medicisContract = new ethers.Contract(medicisAddress, ABI_MEDICIS, signer);

		/**************************************************************************
		**	Linking the Donatori contract to the Medicis Vault
		**************************************************************************/
		const	donatoriAddress = (await Donatori.deployed()).address;
		try {
			const	tx = await medicisContract.setDonatori(donatoriAddress);
			const	txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error(`❌ - Impossible to set Donatori\n`);
			}
		} catch (error) {
			return console.error(`❌ - Impossible to set Donatori: ${error}\n`);
		}

		/**************************************************************************
		**	Linking the Beneficiari contract to the Medicis Vault
		**************************************************************************/
		const	beneficiariAddress = (await Beneficiari.deployed()).address;
		try {
			const	tx = await medicisContract.setBeneficiari(beneficiariAddress);
			const	txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error(`❌ - Impossible to set Beneficiari: ${txResult}\n`);
			}
		} catch (error) {
			return console.error(`❌ - Impossible to set Beneficiari: ${error}\n`);
		}
	}

	if (VERSION === 'WBTC') {
		/**************************************************************************
		**	Deploying Medicis
		**************************************************************************/
		await	deployer.deploy(Medicis, WBTC_ADDRESS, accounts[0], accounts[0]);
		const	medicisAddress = (await Medicis.deployed()).address;

		await	deployer.deploy(Mappings);
		await	deployer.link(Mappings, Donatori);
		await	deployer.deploy(Donatori, medicisAddress,
			['#3f3f3f', '#cc2400', '#fece2e', '#fd7601', '#e24800', '#ff9a00'],
			[1 * 10000000,
			5 * 10000000,
			1 * 100000000,
			5 * 100000000,
			10 * 100000000]
		);
		await	deployer.link(Mappings, Beneficiari);
		await	deployer.deploy(Beneficiari, medicisAddress, 8);

		/**************************************************************************
		**	Setup the signer
		**************************************************************************/
		const	provider = ethers.getDefaultProvider('http://localhost:8545');
		const   signer = new ethers.Wallet(DEPLOYER, provider)
		const	medicisContract = new ethers.Contract(medicisAddress, ABI_MEDICIS, signer);

		/**************************************************************************
		**	Linking the Donatori contract to the Medicis Vault
		**************************************************************************/
		const	donatoriAddress = (await Donatori.deployed()).address;
		try {
			const	tx = await medicisContract.setDonatori(donatoriAddress);
			const	txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error(`❌ - Impossible to set Donatori\n`);
			}
		} catch (error) {
			return console.error(`❌ - Impossible to set Donatori: ${error}\n`);
		}

		/**************************************************************************
		**	Linking the Beneficiari contract to the Medicis Vault
		**************************************************************************/
		const	beneficiariAddress = (await Beneficiari.deployed()).address;
		try {
			const	tx = await medicisContract.setBeneficiari(beneficiariAddress);
			const	txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error(`❌ - Impossible to set Beneficiari: ${txResult}\n`);
			}
		} catch (error) {
			return console.error(`❌ - Impossible to set Beneficiari: ${error}\n`);
		}
	}
};

