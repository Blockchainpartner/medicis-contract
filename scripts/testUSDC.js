/******************************************************************************
**	@Author:				Thomas Bouder <Tbouder>
**	@Email:					Tbouder@protonmail.com
**	@Date:					Monday June 28th 2021
**	@Filename:				testUSDC.js
******************************************************************************/

const ethers = require('ethers');
const Contract = require('web3-eth-contract');
const Medicis = artifacts.require("Medicis");
const Donatori = artifacts.require("Donatori");
const Beneficiari = artifacts.require("Beneficiari");
const StrategyLenderYieldOptimiser = artifacts.require("StrategyLenderYieldOptimiser");
const GenericAave = artifacts.require("GenericAave");

const	ERC20_CONTRACT = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
let		MEDICIS_CONTRACT = '0x0';
let		STRATEGY_GENERIC_LEV_COMP_FARM = '0x0';

const	ABI_ERC20 = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"authorizer","type":"address"},{"indexed":true,"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"AuthorizationCanceled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"authorizer","type":"address"},{"indexed":true,"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"AuthorizationU9sed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"}],"name":"Blacklisted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newBlacklister","type":"address"}],"name":"BlacklisterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"burner","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Burn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newMasterMinter","type":"address"}],"name":"MasterMinterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":false,"internalType":"uint256","name":"minterAllowedAmount","type":"uint256"}],"name":"MinterConfigured","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"oldMinter","type":"address"}],"name":"MinterRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":false,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[],"name":"Pause","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newAddress","type":"address"}],"name":"PauserChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newRescuer","type":"address"}],"name":"RescuerChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"}],"name":"UnBlacklisted","type":"event"},{"anonymous":false,"inputs":[],"name":"Unpause","type":"event"},{"inputs":[],"name":"CANCEL_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RECEIVE_WITH_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"TRANSFER_WITH_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"authorizer","type":"address"},{"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"authorizationState","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"blacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"blacklister","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"authorizer","type":"address"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"cancelAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"},{"internalType":"uint256","name":"minterAllowedAmount","type":"uint256"}],"name":"configureMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"currency","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"decrement","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"increment","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"tokenName","type":"string"},{"internalType":"string","name":"tokenSymbol","type":"string"},{"internalType":"string","name":"tokenCurrency","type":"string"},{"internalType":"uint8","name":"tokenDecimals","type":"uint8"},{"internalType":"address","name":"newMasterMinter","type":"address"},{"internalType":"address","name":"newPauser","type":"address"},{"internalType":"address","name":"newBlacklister","type":"address"},{"internalType":"address","name":"newOwner","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"newName","type":"string"}],"name":"initializeV2","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"lostAndFound","type":"address"}],"name":"initializeV2_1","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"isBlacklisted","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"masterMinter","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"}],"name":"minterAllowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pauser","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"receiveWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"}],"name":"removeMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"tokenContract","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"rescueERC20","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"rescuer","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"transferWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"unBlacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newBlacklister","type":"address"}],"name":"updateBlacklister","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newMasterMinter","type":"address"}],"name":"updateMasterMinter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newPauser","type":"address"}],"name":"updatePauser","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newRescuer","type":"address"}],"name":"updateRescuer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}];


const	ABI_MEDICIS = [
	'function beneficiari() external view returns (address)',
	'function donatori() external view returns (address)',
	'function setDonatori(address _donatori) public',
	'function setBeneficiari(address _beneficiari) public',
	'function deposit(address donatore, tuple(address recipient, uint256 grant)[] grants) external returns (uint256)',
	'function withdraw(address recipient, tuple(address recipient, uint256 grant)[] grants) external returns (uint256)',
	'function harvest() external returns (uint256)',
	'function pricePerShare() external view returns (uint256)',
	'function totalSupply() external view returns (uint256)',
	'function debt() external view returns (uint256)',
	'function getShareForBeneficiario(address donatore, address beneficiario) external view returns (uint256)',
	'function addStrategy(address strategy, uint256 _debtRatio, uint256 _rateLimit, uint256 _performanceFee) external',
	'function expectedReturn(address strategy) external view returns(uint256)',
	'function debtOutstanding(address strategy) external view returns(uint256)',
	'function setRewards(address _rewards) public',
	'function _shareValue(uint256 share) public pure returns (uint256)'
];
const	ABI_DONATORI = [
	'function getBeneficiarioGrant(address from, address to) public view returns (uint256)',
	'function getArt(address donatore) public pure returns (string memory svg)',
	'function balanceOf(address donatore) public pure returns (uint256)',
	'function shareOf(address donatore) public pure returns (uint256)'
];
const	ABI_BENEFICIARIO = [
	'function pricePerShare(address beneficiario) public view returns (uint256)',
    'function getHarvested(address beneficiario) public view returns (uint256)'
];

const	ABI_STRATEGY = [
	'function want() public view returns (address)',
	'function estimatedTotalAssets() public view returns (uint256)',
	'function estimatePrepareReturn() public view returns (uint256 _profit, uint256 _loss, uint256 _debtPayment, uint256 _total, uint256 _debt)',
	'function setKeeper(address _keeper) external',
	'function harvest() external',
	'function lendStatuses() public view returns (tuple(string name, uint256 assets, uint256 rate, address add)[] memory)',

];

const	DECIMALS = 6;
const	USERS = ['👽', '🙂', '🥶', '🤬', '🤢']
const	ADDRESSES = [
	'0xB8c93dF4E1e6b1097889554D9294Dfb42814063a',
	'0xc8cBE7dDc64e9b0A924a6EF1c9D1B27a3F2F5eAe',
	'0x959BA9537348C248AFa04281d01d196af27CAdaD',
	'0x14bD3081ae1e823B8923b14Da6976faA6DE5847A',
	'0x611BC196E67df86D176167F3EF85a7C35784CD39'
];
const	USERS_PK = [
	'0x72bddca8b8fee4ca061adab9833b03f400586e65a73689f6852ce8d7d52ffa3f',
	'0x52632b8682ea4f10a7f79bf360b8b3ee4c344900e3c1937e30f3676dc3ea3f91',
	'0xadc9cf0bad1cdcc4f355e4b3346dd0d3f320d95e9d6d03820fa4665895a25c3c',
	'0x275f6fa502a4e99733aa76fc7a3f8dc4c7acef5ba521e7a8c464ba172dd62d6b',
	'0xe0f45731796573de6cc1b3240988c958e015a0f7c9960d13fb3a290b52367c86',
];


let	erc20Contract;
let	medicisContract;
let	beneficiariContract;
let	donatoriContract;

async function getVaultInformations() {
	const	pricePerShare = ethers.utils.formatUnits((await medicisContract.pricePerShare()), DECIMALS);
	console.info(`\t💵 - PRICE_PER_SHARE:      ${pricePerShare}`);
	const	totalSupply = (await medicisContract.totalSupply());
	console.info(`\t🏦 - TOTAL_SHARES:         ${totalSupply}`);
	const	balanceOf = (await erc20Contract.balanceOf(MEDICIS_CONTRACT));
	console.info(`\t💼 - UNDERLYING_BALANCE:   ${balanceOf}`);
	const	debt = (await medicisContract.debt());
	console.info(`\t🎁 - DEBT:                 ${debt}\n`);
}
async function getBeneficiarioPosition(d, i = 0) {
	if (i >= USERS.length) {
		return;
	}
	const	grant = (await donatoriContract.getBeneficiarioGrant(ADDRESSES[d], ADDRESSES[i]));
	const	share = (await medicisContract.getShareForBeneficiario(ADDRESSES[d], ADDRESSES[i]));
	const	balanceOf = (await erc20Contract.balanceOf(ADDRESSES[i]));
	const	pricePerShare = ethers.utils.formatUnits((await beneficiariContract.pricePerShare(ADDRESSES[i])), DECIMALS);
	const	getHarvested = (await beneficiariContract.getHarvested(ADDRESSES[i]));
	if (USERS[d] === USERS[i]) {
		console.log(`| ${USERS[d]}/${USERS[i]}  ▸  ${share} shares | ${pricePerShare} specific PPS | ${getHarvested} harvested | ${balanceOf} want`);
	} else {
		console.log(`| ${USERS[d]}/${USERS[i]}  ▸  ${share} shares | ${grant} grant`);
	}
	await getBeneficiarioPosition(d, i + 1);
}
async function getDonatoreNFT(d = 0) {
	if (d === 0) {
		console.log(`┌──────────────────────────────────────────────────────`);
	}
	if (d >= USERS.length) {
		console.log(`└──────────────────────────────────────────────────────`);
		return;
	}	
	await getBeneficiarioPosition(d);
	await getDonatoreNFT(d + 1);
}

async function	approve(where, amount) {
	const   approveTx = await erc20Contract.approve(where, amount);
	const	approveTxResult = await approveTx.wait();
	if (approveTxResult.status !== 1) {
		console.error('❌ - APPROVE ERROR');
		return
	}
	console.info('✅ - APPROVE SUCCESS');
	await getVaultInformations();
	await getDonatoreNFT();
}
async function	deposit(who, grants) {
	const   depositTx = await medicisContract.deposit(who, grants);
	const	depositTxResult = await depositTx.wait();
	if (depositTxResult.status !== 1) {
		console.error('❌ - DEPOSIT ERROR');
		return
	}
	console.info('✅ - DEPOSIT SUCCESS');
	await getVaultInformations();
	await getDonatoreNFT();
}

module.exports = async function () {
	const	provider = ethers.getDefaultProvider('http://localhost:8545');
	const   signer = new ethers.Wallet(USERS_PK[0], provider)

	const	USDC_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
	const	CUSDC_ADDRESS = '0x39aa39c021dfbae8fac545936693ac917d5e7563';
	const	AUSDC_ADDRESS = '0xbcca60bb61934080951369a648fb03df4f96263c';

	/**************************************************************************
	**	Retrieve the medicis contracts, strategies and utils
	**************************************************************************/
	MEDICIS_CONTRACT = (await Medicis.deployed()).address;
	DONATORI_ADDRESS = (await Donatori.deployed()).address;
	BENEFICIARI_ADDRESS = (await Beneficiari.deployed()).address;
	STRATEGY_GENERIC_LEV_COMP_FARM = (await StrategyGenericLevCompFarm.deployed()).address;
	STRATEGY_LENDER_YIELD_OPTIMISER = (await StrategyLenderYieldOptimiser.deployed()).address;
	GENERIC_AAVE = (await GenericAave.deployed()).address;

	/**************************************************************************
	**	Connect USERS_PK[0] as signer and retrieve contract addresses
	**************************************************************************/
	erc20Contract = new ethers.Contract(ERC20_CONTRACT, ABI_ERC20, signer);
	cErc20Contract = new ethers.Contract(CUSDC_ADDRESS, ABI_ERC20, signer);
	aErc20Contract = new ethers.Contract(AUSDC_ADDRESS, ABI_ERC20, signer);
	medicisContract = new ethers.Contract(MEDICIS_CONTRACT, ABI_MEDICIS, signer);
	beneficiariContract = new ethers.Contract(BENEFICIARI_ADDRESS, ABI_BENEFICIARIO, signer);	
	donatoriContract = new ethers.Contract(DONATORI_ADDRESS, ABI_DONATORI, signer);	
	strategyLenderYieldOptimiser = new ethers.Contract(STRATEGY_LENDER_YIELD_OPTIMISER, ABI_STRATEGY, signer);
	genericAAVE = new ethers.Contract(GENERIC_AAVE, ABI_STRATEGY, signer);

	const   estimatedTotalAssets2 = ethers.utils.formatUnits(await strategyLenderYieldOptimiser.estimatedTotalAssets(), 0);
	console.log(`🎁 - Pending rewards strategyLenderYieldOptimiser: ${estimatedTotalAssets2}`)
	
	// return

	/**************************************************************************
	**	In order to test this strategy, we will need some USDC. Steal the
	**	richest address
	**************************************************************************/
	try {
		Contract.setProvider('http://localhost:8545');
		await new Contract(ABI_ERC20, ERC20_CONTRACT).methods.transfer(ADDRESSES[0], 177_900_000_000).send({from: "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503"})
		console.info('✅ - Success while stealing the richest address\n');
	} catch (error) {
		console.warn('⚠️ - Impossible to steal the richest address\n');
	}

	/**************************************************************************
	**	Approving the ERC20 tx for donatore
	**************************************************************************/
	await approve(MEDICIS_CONTRACT, 80_000_000_000)

	// /**************************************************************************
	// **	Performing a deposit in the Medicis Vault
	// **************************************************************************/
	await deposit(ADDRESSES[0], [[ADDRESSES[1], 40_000_000_000], [ADDRESSES[2], 40_000_000_000]])

	await getVaultInformations();
	await getDonatoreNFT();
	console.log()

	try {
		const   tx = await medicisContract.setRewards(ADDRESSES[0]);
		await	tx.wait();
		console.info('✅ - Success while trying to harvest the GenericLevCompFarmContract\n');
	} catch (error) {
		const	err = error?.error?.body;
		const	jsonErr = JSON.parse(err);
		console.error(`❌ - Impossible to harvest : ${jsonErr?.error?.message}\n`)
		return;
	}


	try {
		const   tx = await strategyLenderYieldOptimiser.harvest();
		await	tx.wait();
		const   estimatedTotalAssets = ethers.utils.formatUnits(await strategyLenderYieldOptimiser.estimatedTotalAssets(), 0);
		console.log(estimatedTotalAssets)

		console.info('✅ - Success while trying to harvest the strategyLenderYieldOptimiser\n');
	} catch (error) {
		const	err = error?.error?.body;
		const	jsonErr = JSON.parse(err);
		console.error(`❌ - Impossible to harvest : ${jsonErr?.error?.message}\n`)
		return;
	}
	await getVaultInformations();
	await getDonatoreNFT();


	const svg = await donatoriContract.getArt(ADDRESSES[0]);
	console.log(svg)

};
