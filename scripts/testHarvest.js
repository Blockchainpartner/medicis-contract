/******************************************************************************
**	@Author:				Thomas Bouder <Tbouder>
**	@Email:					Tbouder@protonmail.com
**	@Date:					Thursday June 17th 2021
**	@Filename:				test.js
******************************************************************************/

const ethers = require('ethers');
const BasicToken = artifacts.require("BasicToken");
const Medicis = artifacts.require("Medicis");

let ERC20_CONTRACT = '0x0';
let MEDICIS_CONTRACT = '0x0';
let BENEFICIARIO_CONTRACT = '0x0';

const	ABI_ERC20_APPROVE = [
	'function performMint(address to, uint256 amount) external',
	'function transfer(address recipient, uint256 amount) external',
	'function approve(address spender, uint256 amount) external',
	'function balanceOf(address ownser) external view returns (uint256)'
];
const	ABI_MEDICIS = [
	'function beneficiarioPosition() external view returns (address)',
	'function deposit(address donatore, tuple(address recipient, uint256 grant)[] grants) external returns (uint256)',
	'function withdraw(address recipient, tuple(address recipient, uint256 grant)[] grants) external returns (uint256)',
	'function harvest() external returns (uint256)',
	'function pricePerShare() external view returns (uint256)',
	'function totalSupply() external view returns (uint256)',
	'function getGrantForBeneficiario(address donatore, address beneficiario) external view returns (uint256)',
	'function getShareForBeneficiario(address donatore, address beneficiario) external view returns (uint256)',
	'function DEBUGG() external view returns ( uint256, uint256, uint256, uint256, uint256)',
];
const	ABI_BENEFICIARIO = [
	'function pricePerShare(address beneficiario) public view returns (uint256)',
    'function getHarvested(address beneficiario) public view returns (uint256)'

];

const	DONATORES = ['👽', '🙂', '🥶', '🤬', '🤢']
const	BENEFICIARI = ['👽', '🙂', '🥶', '🤬', '🤢'];
const	DONATORES_ADDRESSES = [
	'0xB8c93dF4E1e6b1097889554D9294Dfb42814063a',
	'0xc8cBE7dDc64e9b0A924a6EF1c9D1B27a3F2F5eAe',
	'0x959BA9537348C248AFa04281d01d196af27CAdaD',
	'0x14bD3081ae1e823B8923b14Da6976faA6DE5847A',
	'0x611BC196E67df86D176167F3EF85a7C35784CD39'
];
const	BENEFICIARI_ADDRESSES = [
	'0xB8c93dF4E1e6b1097889554D9294Dfb42814063a',
	'0xc8cBE7dDc64e9b0A924a6EF1c9D1B27a3F2F5eAe',
	'0x959BA9537348C248AFa04281d01d196af27CAdaD',
	'0x14bD3081ae1e823B8923b14Da6976faA6DE5847A',
	'0x611BC196E67df86D176167F3EF85a7C35784CD39'
];
const	BENEFICIARI_PK = [
	'0x72bddca8b8fee4ca061adab9833b03f400586e65a73689f6852ce8d7d52ffa3f',
	'0x52632b8682ea4f10a7f79bf360b8b3ee4c344900e3c1937e30f3676dc3ea3f91',
	'0xadc9cf0bad1cdcc4f355e4b3346dd0d3f320d95e9d6d03820fa4665895a25c3c',
	'0x275f6fa502a4e99733aa76fc7a3f8dc4c7acef5ba521e7a8c464ba172dd62d6b',
	'0xe0f45731796573de6cc1b3240988c958e015a0f7c9960d13fb3a290b52367c86',
];


let	erc20Contract;
let	medicisContract;
let	beneficiariosContract;

async function getVaultInformations() {
	const	pricePerShare = ethers.utils.formatUnits((await medicisContract.pricePerShare()), 18);
	console.info(`\t💵 - PRICE_PER_SHARE:      ${pricePerShare}`);
	const	totalSupply = (await medicisContract.totalSupply());
	console.info(`\t🏦 - TOTAL_SHARES:         ${totalSupply}`);
	const	balanceOf = (await erc20Contract.balanceOf(MEDICIS_CONTRACT));
	console.info(`\t💼 - UNDERLYING_BALANCE:   ${balanceOf}\n`);
}
async function getBeneficiarioPosition(d, i = 0) {
	if (i >= BENEFICIARI.length) {
		return;
	}
	const	grant = (await medicisContract.getGrantForBeneficiario(DONATORES_ADDRESSES[d], BENEFICIARI_ADDRESSES[i]));
	const	share = (await medicisContract.getShareForBeneficiario(DONATORES_ADDRESSES[d], BENEFICIARI_ADDRESSES[i]));
	const	balanceOf = (await erc20Contract.balanceOf(BENEFICIARI_ADDRESSES[i]));
	const	pricePerShare = ethers.utils.formatUnits((await beneficiariosContract.pricePerShare(BENEFICIARI_ADDRESSES[i])), 18);
	const	getHarvested = (await beneficiariosContract.getHarvested(BENEFICIARI_ADDRESSES[i]));
	if (DONATORES[d] === BENEFICIARI[i]) {
		console.log(`| ${DONATORES[d]}/${BENEFICIARI[i]}  ▸  ${share} shares | ${pricePerShare} specific PPS | ${getHarvested} harvested | ${balanceOf} want`);
	} else {
		console.log(`| ${DONATORES[d]}/${BENEFICIARI[i]}  ▸  ${share} shares | ${grant} grant`);
	}
	await getBeneficiarioPosition(d, i + 1);
}
async function getDonatoreNFT(d = 0) {
	if (d === 0) {
		console.log(`┌──────────────────────────────────────────────────────`);
	}
	if (d >= DONATORES.length) {
		console.log(`└──────────────────────────────────────────────────────`);
		return;
	}	
	await getBeneficiarioPosition(d);
	await getDonatoreNFT(d + 1);
}

async	function mintUnderlyingFor(to, amount) {
	const	transferERC20Tx = await erc20Contract.performMint(to, amount);
	const	transferERC20TxResult = await transferERC20Tx.wait();
	if (transferERC20TxResult.status !== 1) {
		console.error('❌ - MINT ERROR');
		return
	}
	console.info('✅ - MINT SUCCESS');
	await getVaultInformations();
	await getDonatoreNFT();
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
async function	withdraw(who, grants) {
	const   tx = await medicisContract.withdraw(who, grants);
	const	txResult = await tx.wait();
	if (txResult.status !== 1) {
		console.error('❌ - WITHDRAW ERROR');
		return
	}
	console.info('✅ - WITHDRAW SUCCESS');
	await getVaultInformations();
	await getDonatoreNFT();
}

async function harvest(whoPK) {
	const	provider = ethers.getDefaultProvider('http://localhost:8545');
	const   signer = new ethers.Wallet(whoPK, provider)
	const	medicisContractBenef1 = new ethers.Contract(MEDICIS_CONTRACT, ABI_MEDICIS, signer);
	const   tx = await medicisContractBenef1.harvest();
	const	txResult = await tx.wait();
	if (txResult.status !== 1) {
		console.error('❌ - HARVEST ERROR');
		return
	}
	console.info('✅ - HARVEST SUCCESS');
	await getVaultInformations();
	await getDonatoreNFT();
}

async function	depositYieldHarvest() {
	await mintUnderlyingFor(DONATORES_ADDRESSES[0], 40000);

	/**************************************************************************
	**	Approving the ERC20 tx for donatore
	**************************************************************************/
	// console.log(`\n👉 ${DONATORES[0]} approve the deposit of 40000`)
	await approve(MEDICIS_CONTRACT, 40000)

	/**************************************************************************
	**	Performing a deposit in the Medicis Vault
	**************************************************************************/
	// console.log(`\n👉 ${DONATORES[0]} deposit 40000 underlying for the 4 BENEFICIARI : ${BENEFICIARI[1]}, ${BENEFICIARI[2]}, ${BENEFICIARI[3]} & ${BENEFICIARI[4]}`)
	await deposit(DONATORES_ADDRESSES[0], [
			[BENEFICIARI_ADDRESSES[1], 10000],
			[BENEFICIARI_ADDRESSES[2], 10000],
			// [BENEFICIARI_ADDRESSES[3], 10000],
			// [BENEFICIARI_ADDRESSES[4], 10000]
		]
	)

	/**************************************************************************
	**	Faking yield by sending tokens
	**************************************************************************/
	// console.log(`\n👉 The strategy is successfull and 4000 underlying are earned as yield`)
	await mintUnderlyingFor(MEDICIS_CONTRACT, 4000);

	/**************************************************************************
	**	Benef 1 harvest 
	**************************************************************************/
	// console.log(`\n👉 ${BENEFICIARI[1]} harvest it's position`)
	await harvest(BENEFICIARI_PK[1])
	await mintUnderlyingFor(MEDICIS_CONTRACT, 2000);
	await harvest(BENEFICIARI_PK[1])



	/**************************************************************************
	**	Approving the ERC20 tx for donatore
	**************************************************************************/
	// console.log(`\n👉 ${DONATORES[0]} approve the deposit of 10000`)
	// await mintUnderlyingFor(DONATORES_ADDRESSES[0], 10000);
	// await approve(MEDICIS_CONTRACT, 10000)

	/**************************************************************************
	**	Performing a deposit in the Medicis Vault
	**************************************************************************/
	// console.log(`\n👉 ${DONATORES[0]} deposit 100000 underlying for the 2 BENEFICIARI : ${BENEFICIARI[1]}, ${BENEFICIARI[2]}`)
	// await deposit(DONATORES_ADDRESSES[0], [
	// 		[BENEFICIARI_ADDRESSES[1], 8000],
	// 		[BENEFICIARI_ADDRESSES[2], 2000],
	// 	]
	// )

	// await mintUnderlyingFor(MEDICIS_CONTRACT, 1000);

	// await mintUnderlyingFor(MEDICIS_CONTRACT, 1000);
	// await harvest(BENEFICIARI_PK[3])
	// await harvest(BENEFICIARI_PK[1])
	// await harvest(BENEFICIARI_PK[2])
	// await harvest(BENEFICIARI_PK[3])
	// await harvest(BENEFICIARI_PK[4])


	// await withdraw(
	// 	DONATORES_ADDRESSES[0], [
	// 		[BENEFICIARI_ADDRESSES[1], 20000],
	// 		[BENEFICIARI_ADDRESSES[2], 20000],
	// 		[BENEFICIARI_ADDRESSES[3], 20000],
	// 		[BENEFICIARI_ADDRESSES[4], 20000]
	// 	]);

	// await mintUnderlyingFor(MEDICIS_CONTRACT, 4000);
	// await getVaultInformations();
	// await getDonatoreNFT();

	// await harvest(BENEFICIARI_PK[1])
	
	console.log('\n')
}

module.exports = async function () {
	const instanceERC20 = await BasicToken.deployed();
	ERC20_CONTRACT = instanceERC20.address;
	const instanceMedicis = await Medicis.deployed();
	MEDICIS_CONTRACT = instanceMedicis.address;
	const	provider = ethers.getDefaultProvider('http://localhost:8545');
	const   signer = new ethers.Wallet(BENEFICIARI_PK[0], provider)
	erc20Contract = new ethers.Contract(ERC20_CONTRACT, ABI_ERC20_APPROVE, signer);
	medicisContract = new ethers.Contract(MEDICIS_CONTRACT, ABI_MEDICIS, signer);
	const	beneficiarioPosition = (await medicisContract.beneficiarioPosition());
	BENEFICIARIO_CONTRACT = beneficiarioPosition;
	beneficiariosContract = new ethers.Contract(BENEFICIARIO_CONTRACT, ABI_BENEFICIARIO, signer);

	await depositYieldHarvest()
};
