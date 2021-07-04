// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/Mapping.sol";

contract Beneficiari is ERC721, Pausable { 
    using Counters for Counters.Counter;
	using Mappings for Mappings.Mapping;
    
    struct Position {
		uint256 totalGrants;
		uint256 totalShares;
		uint256 totalHarvested;
		uint256 sharePrice;
		Mappings.Mapping donatori;
		mapping (address => uint256) shares;
	}
    
    address public medicis = address(0);
	modifier onlyMedicis() {
		require(msg.sender == medicis, "!authorized");
		_;
	}
    
    Counters.Counter private _tokenID;
	mapping (uint256 => Position) public positions;
	mapping (address => uint256) public positionForAddress;
	uint256 private decimals = 0;
	
	constructor(address _medicis, uint256 _decimals) ERC721("Medicis V1 Position Beneficiari", "MED-V1-BEN") {
        medicis = _medicis;
        decimals = _decimals;
		_pause();
	}

	/*******************************************************************************
    **	@notice
    **		Getter functon to get, for a specific beneficiario, the totalShares
    **  @param beneficiario: Address of the beneficiario
    **  @return: The number of shares minted for this beneficiario.
    *******************************************************************************/
    function getShares(address beneficiario) public view returns (uint256) {
        uint256 tokenID = positionForAddress[beneficiario];
        if (tokenID == 0) {
            return 0;
        }
	    return positions[tokenID].totalShares;
	}

	/*******************************************************************************
    **	@notice
    **		Getter functon to get, for a specific beneficiario/donatore pair, the
	**		number of shares from a specific donatore.
    **  @param donatore: Address of the donatore
    **  @param beneficiario: Address of the beneficiario
    **  @return: The number of shares minted for this beneficiario by this donatore
    *******************************************************************************/
    function getShareFromDonatore(address donatore, address beneficiario) public view returns (uint256) {
        uint256 tokenID = positionForAddress[beneficiario];
        if (tokenID == 0) {
            return 0;
        }
	    return positions[tokenID].shares[donatore];
	}

	/*******************************************************************************
    **	@notice
    **		This function is called when a Donatore grant some underlying to a
	**		beneficiario. It's position will be minted or upgraded based on the
	**		grant from the medicis contract
    **  @param donatore: Address of the donatore
    **  @param beneficiario: Address of the beneficiario
    **  @param grant: amount granted
	**  @param shares: number of shares minted from this amount
    **  @return: The tokenID of the corresponding NFT
    *******************************************************************************/
	function populate(address donatore, address beneficiario, uint256 grant, uint256 shares) external onlyMedicis() returns (uint256) {
	    if (positionForAddress[beneficiario] == 0) {
	        return _mintBeneficiari(donatore, beneficiario, grant, shares);
	    }
	    return _increaseMintedBeneficiari(donatore, beneficiario, grant, shares);
	}
	function _mintBeneficiari(address donatore, address beneficiario, uint256 grant, uint256 shares) internal returns (uint256) {
  		_tokenID.increment();
  		
		uint256 newtokenID = _tokenID.current();
		_mint(beneficiario, newtokenID);
		positionForAddress[beneficiario] = newtokenID;
		positions[newtokenID].totalGrants += grant;
		positions[newtokenID].totalShares += shares;
		positions[newtokenID].shares[donatore] += shares;
		positions[newtokenID].donatori.push(donatore);
		return newtokenID;  
	}
	function _increaseMintedBeneficiari(address donatore, address beneficiario, uint256 grant, uint256 shares) internal returns (uint256) {
		uint256 tokenID = positionForAddress[beneficiario];
		positions[tokenID].totalGrants += grant;
		positions[tokenID].totalShares += shares;
		positions[tokenID].shares[donatore] += shares;
		positions[tokenID].donatori.push(donatore);
		return tokenID;
	}
	
	/*******************************************************************************
    **	@notice
    **		This function is called when a Donatore withdraw some underlying from a
	**		beneficiario. It's position will be downgraded based on the withdraw
	**		from the medicis contract
    **  @param donatore: Address of the donatore
    **  @param beneficiario: Address of the beneficiario
    **  @param grant: amount granted
	**  @param shares: number of shares minted from this amount
    **  @return: The tokenID of the corresponding NFT
    *******************************************************************************/
	function unpopulate(address donatore, address beneficiario, uint256 grant, uint256 shares) external onlyMedicis() returns (uint256) {
	    return _decreaseMintedBeneficiari(donatore, beneficiario, grant, shares);
	}
	function _decreaseMintedBeneficiari(address donatore, address beneficiario, uint256 grant, uint256 shares) internal returns (uint256) {
		uint256 tokenID = positionForAddress[beneficiario];
		positions[tokenID].totalGrants -= grant;
		positions[tokenID].totalShares -= shares;
		positions[tokenID].shares[donatore] -= shares;
		if (positions[tokenID].shares[donatore] == 0 && donatore != beneficiario) {
			positions[tokenID].donatori.remove(donatore);
		}
		return tokenID;
	}

	/*******************************************************************************
	**	@notice
	**		Helper function to get, for a specific beneficiario, the list of it's
	**		donatori.
	**  @param donatore: The address of the donatore
	**  @return: An array of address corresponding to the donatori
	*******************************************************************************/
	function donatoriList(address beneficiario) public view returns (address[] memory addresses) {
		if (positionForAddress[beneficiario] == 0) {
			return addresses;
		}
		addresses = positions[positionForAddress[beneficiario]].donatori.list();
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	//TEMP ////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////
	/*******************************************************************************
    **	@notice Retrieve a specific shareValue for a beneficiario
    **  @param donatore: Address of the donatore
    **  @param beneficiario: Address of the beneficiario
    **  @return: The number of shares minted for this beneficiario by this donatore
    *******************************************************************************/
	function shareValue(address beneficiario, uint256 shares) public view returns (uint256) {
        uint256 tokenID = positionForAddress[beneficiario];
        if (tokenID == 0) {
            return 0;
        }
		uint256 totalGrants = positions[tokenID].totalGrants;
		uint256 totalShares = positions[tokenID].totalShares;
		uint256 totalHarvested = positions[tokenID].totalHarvested;
		if (totalGrants == 0) {
			return 0;
		}
		if (totalShares < totalHarvested) {
			return 0;
		}
	    return shares * (totalShares - totalHarvested) / totalGrants;
	}

	function pricePerShare(address beneficiario) public view returns (uint256) {
        uint256 tokenID = positionForAddress[beneficiario];
        if (tokenID == 0) {
            return 0;
        }
	    if (positions[tokenID].totalShares == 0) {
	        return 10 ** decimals; // price of 1:1
	    } else {
		    return shareValue(beneficiario, 10 ** decimals);
	    }
	}

	function onHarvest(address beneficiario, uint256 shareHarvested) external onlyMedicis() {
		uint256 tokenID = positionForAddress[beneficiario];
        if (tokenID == 0) {
            return;
        }
		positions[tokenID].totalHarvested += shareHarvested;
	}

    function getScaledShares(address beneficiario) public view returns (uint256) {
        uint256 tokenID = positionForAddress[beneficiario];
        if (tokenID == 0) {
            return 0;
        }
	    return shareValue(beneficiario, positions[tokenID].totalShares);
	}

    function getHarvested(address beneficiario) public view returns (uint256) {
        uint256 tokenID = positionForAddress[beneficiario];
        if (tokenID == 0) {
            return 0;
        }
	    return positions[tokenID].totalHarvested;
	}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(from == address(0) || !paused(), "ERC721Pausable: token transfer while paused");
    }

	function unpause() external onlyMedicis() {
		_unpause();
	}
}
