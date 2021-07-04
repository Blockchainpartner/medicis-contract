// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./utils/WithSVG.sol";
import "./utils/Mapping.sol";

interface MedicisAPI {
    function token() external view returns (address);
    function underlyingDecimals() external view returns (uint256);
    function _shareValue(uint256 shares) external view returns (uint256);
}

contract Donatori is ERC721, Pausable, WithSVG { 
    using Counters for Counters.Counter;
	using Mappings for Mappings.Mapping;
    MedicisAPI public Medicis;
    IERC20Metadata public want;

	struct Position {
		uint256 totalGrants;
		uint256 totalShares;
		Mappings.Mapping beneficiari;
		mapping (address => uint256) grants; 
	}
		
	address public medicis = address(0);
	modifier onlyMedicis() {
		require(msg.sender == medicis, "!authorized");
		_;
	}
		
	Counters.Counter private _tokenID;
	mapping (uint256 => Position) public positions;
	mapping (address => uint256) public positionForAddress;
	
	constructor(
		address _medicis,
		string[6] memory colors,
		uint256[5] memory breakdown
	) ERC721("Medicis V1 Position Donatori", "MED-V1-DON") {
		medicis = _medicis;
		Medicis = MedicisAPI(_medicis);
		want = IERC20Metadata(Medicis.token());
		setColors(colors[0], colors[1], colors[2], colors[3], colors[4], colors[5]);
		setBreakdown(breakdown[0], breakdown[1], breakdown[2], breakdown[3], breakdown[4]);
		_pause();
	}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(from == address(0) || !paused(), "ERC721Pausable: token transfer while paused");
    }

	function mint(address to) external onlyMedicis() returns (uint256) {
		_tokenID.increment();
		uint256 newtokenID = _tokenID.current();
		_mint(to, newtokenID);
		positionForAddress[to] = newtokenID;
		return newtokenID;
	}

	function setDonatorForAddress(address _donatore, uint256 tokenID) external onlyMedicis() {
		positionForAddress[_donatore] = tokenID;
	}
	function pushBeneficiario(uint256 tokenID, address to) external onlyMedicis() {
		positions[tokenID].beneficiari.push(to);
	}
	function incGrantForBeneficiario(uint256 tokenID, address to, uint256 grant) external onlyMedicis() {
		positions[tokenID].grants[to] += grant;
	}
	function incGrant(uint256 tokenID, uint256 grant) external onlyMedicis() {
		positions[tokenID].totalGrants += grant;
	}
	function incShare(uint256 tokenID, uint256 share) external onlyMedicis() {
		positions[tokenID].totalShares += share;
	}
	function withdrawPosition(uint256 tokenID, address to, uint256 grant, uint256 share) external onlyMedicis() {
		positions[tokenID].totalGrants -= grant;
		positions[tokenID].grants[to] -= grant;
		positions[tokenID].totalShares -= share;
		if (positions[tokenID].grants[to] == 0 && positionForAddress[to] != tokenID) {
			positions[tokenID].beneficiari.remove(to);
		}
	}


	/*******************************************************************************
   	**	@notice
	**		For a specific donatore, find the grants for a beneficiario
	**  @return: The amount of grants for this beneficiario.
	*******************************************************************************/
	function getBeneficiarioGrant(address from, address to) external view returns (uint256) {
		if (positionForAddress[from] == 0) {
			return 0;
		}
		return positions[positionForAddress[from]].grants[to];
	}
	function getBeneficiarioGrant(uint256 tokenID, address to) external view returns (uint256) {
		return positions[tokenID].grants[to];
	}

	/*******************************************************************************
	**	@notice
	**		Retrieve the number of beneficiari for a specific tokenID
	**  @param tokenID: ID of the token
	**  @return: Number of beneficiari
	*******************************************************************************/
	function getBeneficiariLen(uint256 tokenID) public view returns (uint256) {
		return positions[tokenID].beneficiari.length();
	}
	function getBeneficiariLen(address donatore) public view returns (uint256) {
		if (positionForAddress[donatore] == 0) {
			return 0;
		}
		return positions[positionForAddress[donatore]].beneficiari.length();
	}

	/*******************************************************************************
	**	@notice Retrieve a tokenID for a specific donatore
	**  @param donatore: The address of the donatore
	**  @return: The donatore's tokenID
	*******************************************************************************/
	function getDonatorForAddress(address donatore) external view returns (uint256) {
		return positionForAddress[donatore];
	}

	/*******************************************************************************
	**	@notice
	**		Give us the current balance of token staked by the donatore in
	**	  this contract.
	**  @dev
	**	  This function is overridding the default "balanceOf" of the ERC-721
	**	  standard.
	**  @param donatore: The address of the donatore
	**  @return: The amount of token staked.
	*******************************************************************************/
	function balanceOf(address donatore) public view override returns (uint256) {
		if (positionForAddress[donatore] == 0) {
			return 0;
		}
		return positions[positionForAddress[donatore]].totalGrants;
	}
	function balanceOf(uint256 tokenID) public view returns (uint256) {
		return positions[tokenID].totalGrants;
	}

	/*******************************************************************************
	**	@notice
	**		Give us the current share for this donatore
	**  @param donatore: The address of the donatore
	**  @return: The amount of shares.
	*******************************************************************************/
	function shareOf(address donatore) public view returns (uint256) {
		if (positionForAddress[donatore] == 0) {
			return 0;
		}
		return positions[positionForAddress[donatore]].totalShares;
	}
	function shareOf(uint256 tokenID) public view returns (uint256) {
		return positions[tokenID].totalShares;
	}

	/*******************************************************************************
	**	@notice
	**		Helper function to get, for a specific donatore, the list of it's
	**		beneficiari.
	**  @param donatore: The address of the donatore
	**  @return: An array of address corresponding to the beneficiari
	*******************************************************************************/
	function beneficiariList(address donatore) public view returns (address[] memory addresses) {
		if (positionForAddress[donatore] == 0) {
			return addresses;
		}
		addresses = positions[positionForAddress[donatore]].beneficiari.list();
	}

	function getArt(address donatore) public view returns (string memory svg) {
		uint256 status = _getArtStatus(balanceOf(donatore));

		string memory mosaic = string(abi.encodePacked(
				'<rect fill="#131314" x="0.17" width="312" height="467"/><g><rect fill="#3f3f3f" opacity="0.4" x="24" y="21" width="264" height="211.2"/>',
				_getArtMosaic(status),
				'<text class="text-right" x="288" y="243" fill="#FFF" font-size="6" font-weight="700">0x',
				toAsciiString(donatore),
				'</text></g>',
				_getArtGrade(status)
			)
		);

		svg = string(abi.encodePacked(
			'data:image/svg+xml;base64,',
			Base64.encode(
				bytes(
					abi.encodePacked(
						'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 312 467" font-family="Verdana"><defs><style>.text-right{text-anchor: end;}</style></defs><line stroke="#FFF" stroke-width="1" x1="24" y1="344" x2="288" y2="344"/><line stroke="#FFF" stroke-width="1" x1="24" y1="376" x2="288" y2="376"/><line stroke="#FFF" stroke-width="1" x1="24" y1="408" x2="288" y2="408"/><line stroke="#FFF" stroke-width="1" x1="24" y1="440" x2="288" y2="440"/><rect x="24" y="344" width="264" height="32" fill="none" /><rect x="24" y="376" width="264" height="32" fill="none" /><rect x="24" y="408" width="264" height="32" fill="none" /><g font-size="15" fill="#FFF">',
						mosaic,
						_getArtText(Medicis.underlyingDecimals(), balanceOf(donatore), Medicis._shareValue(shareOf(donatore)), getBeneficiariLen(donatore), want.symbol()),
						'</g></svg>'
					)
				)
			)
		));
	}
    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
		uint256 status = _getArtStatus(balanceOf(tokenID));

		string memory mosaic = string(abi.encodePacked(
				'<rect fill="#131314" x="0.17" width="312" height="467"/><g><rect fill="#3f3f3f" opacity="0.4" x="24" y="21" width="264" height="211.2"/>',
				_getArtMosaic(status),
				'<text class="text-right" x="288" y="243" fill="#FFF" font-size="6" font-weight="700">#',
				Strings.toString(tokenID),
				'</text></g>',
				_getArtGrade(status)
			)
		);

		return (string(abi.encodePacked(
			'data:image/svg+xml;base64,',
			Base64.encode(
				bytes(
					abi.encodePacked(
						'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 312 467" font-family="Verdana"><defs><style>.text-right{text-anchor: end;}</style></defs><line stroke="#FFF" stroke-width="1" x1="24" y1="344" x2="288" y2="344"/><line stroke="#FFF" stroke-width="1" x1="24" y1="376" x2="288" y2="376"/><line stroke="#FFF" stroke-width="1" x1="24" y1="408" x2="288" y2="408"/><line stroke="#FFF" stroke-width="1" x1="24" y1="440" x2="288" y2="440"/><rect x="24" y="344" width="264" height="32" fill="none" /><rect x="24" y="376" width="264" height="32" fill="none" /><rect x="24" y="408" width="264" height="32" fill="none" /><g font-size="15" fill="#FFF">',
						mosaic,
						_getArtText(Medicis.underlyingDecimals(), balanceOf(tokenID), Medicis._shareValue(shareOf(tokenID)), getBeneficiariLen(tokenID), want.symbol()),
						'</g></svg>'
					)
				)
			)
		)));
	}

	function unpause() external onlyMedicis() {
		_unpause();
	}
}
