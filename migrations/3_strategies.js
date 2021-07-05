/******************************************************************************
**	@Author:				Thomas Bouder <Tbouder>
**	@Email:					Tbouder@protonmail.com
**	@Date:					Thursday June 17th 2021
**	@Filename:				3_strategies.js
******************************************************************************/

const ethers = require('ethers');
const Medicis = artifacts.require("Medicis");
const StrategyLenderYieldOptimiser = artifacts.require("StrategyLenderYieldOptimiser");
const GenericAave = artifacts.require("GenericAave");

const	VERSION = 'USDC';
const	DEPLOYER = '0x72bddca8b8fee4ca061adab9833b03f400586e65a73689f6852ce8d7d52ffa3f';
const	AUSDC_ADDRESS = '0xbcca60bb61934080951369a648fb03df4f96263c';
const	AWBTC_ADDRESS = '0x9ff58f4ffb29fa2266ab25e75e2a8b3503311656';

const	ABI_MEDICIS = [
	'function addStrategy(address strategy, uint256 _debtRatio, uint256 _rateLimit, uint256 _performanceFee) external',
];

const	ABI_LENDER_YIELD_OPTIMISER = [
	'function addLender(address a) public'
]

module.exports = async function (deployer) {
	if (VERSION === 'USDC') {
		/**************************************************************************
		**	Deploying the strategies
		**************************************************************************/
		const	medicisAddress = (await Medicis.deployed()).address;
		await	deployer.deploy(StrategyLenderYieldOptimiser, medicisAddress);
		
		/**************************************************************************
		**	Setup the signer
		**************************************************************************/
		const	provider = ethers.getDefaultProvider('http://localhost:8545');
		const   signer = new ethers.Wallet(DEPLOYER, provider)
		const	medicisContract = new ethers.Contract(medicisAddress, ABI_MEDICIS, signer);

		/**************************************************************************
		**	Linking StrategyLenderYieldOptimiser strategy to the Medicis contract
		**************************************************************************/
		const	lenderYieldOptimiserAddress = (await StrategyLenderYieldOptimiser.deployed()).address;
		try {
			const tx = await medicisContract.addStrategy(
				lenderYieldOptimiserAddress,
				9000, //90%
				2000000000000,
				1000
			);
			const txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error('❌ - Impossible to add lenderYieldOptimiser');
			}
		} catch (error) {
			return console.error(`❌ - Impossible to add lenderYieldOptimiser : ${error}\n`)
		}
		
		/**************************************************************************
		**	Deploying the AaveLender helper
		**************************************************************************/
		await	deployer.deploy(GenericAave, lenderYieldOptimiserAddress, 'AaveLender', AUSDC_ADDRESS);
		const	GenericAaveAddress = (await GenericAave.deployed()).address;
		
		/**************************************************************************
		**	Linking the AaveLender helper to the LenderYieldOptimiser
		**************************************************************************/
		try {
			const lenderYieldOptimiserContract = new ethers.Contract(lenderYieldOptimiserAddress, ABI_LENDER_YIELD_OPTIMISER, signer);
			const tx = await lenderYieldOptimiserContract.addLender(GenericAaveAddress);
			const txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error('❌ - Impossible to link AaveLender');
			}
		} catch (error) {
			return console.error(`❌ - Impossible to link AaveLender : ${error}\n`)
		}
	}

	if (VERSION === 'WBTC') {
		/**************************************************************************
		**	Deploying the strategies
		**************************************************************************/
		const	medicisAddress = (await Medicis.deployed()).address;
		await	deployer.deploy(StrategyLenderYieldOptimiser, medicisAddress);
		
		/**************************************************************************
		**	Setup the signer
		**************************************************************************/
		const	provider = ethers.getDefaultProvider('http://localhost:8545');
		const   signer = new ethers.Wallet(DEPLOYER, provider)
		const	medicisContract = new ethers.Contract(medicisAddress, ABI_MEDICIS, signer);

		/**************************************************************************
		**	Linking StrategyLenderYieldOptimiser strategy to the Medicis contract
		**************************************************************************/
		const	lenderYieldOptimiserAddress = (await StrategyLenderYieldOptimiser.deployed()).address;
		try {
			const tx = await medicisContract.addStrategy(
				lenderYieldOptimiserAddress,
				9000, //90%
				2000000000000,
				1000
			);
			const txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error('❌ - Impossible to add lenderYieldOptimiser');
			}
		} catch (error) {
			return console.error(`❌ - Impossible to add lenderYieldOptimiser : ${error}\n`)
		}
		
		/**************************************************************************
		**	Deploying the AaveLender helper
		**************************************************************************/
		await	deployer.deploy(GenericAave, lenderYieldOptimiserAddress, 'AaveLender', AWBTC_ADDRESS);
		const	GenericAaveAddress = (await GenericAave.deployed()).address;
		
		/**************************************************************************
		**	Linking the AaveLender helper to the LenderYieldOptimiser
		**************************************************************************/
		try {
			const lenderYieldOptimiserContract = new ethers.Contract(lenderYieldOptimiserAddress, ABI_LENDER_YIELD_OPTIMISER, signer);
			const tx = await lenderYieldOptimiserContract.addLender(GenericAaveAddress);
			const txResult = await tx.wait();
			if (txResult.status !== 1) {
				return console.error('❌ - Impossible to link AaveLender');
			}
		} catch (error) {
			return console.error(`❌ - Impossible to link AaveLender : ${error}\n`)
		}
	}


};