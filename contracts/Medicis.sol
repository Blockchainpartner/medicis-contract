// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./utils/WithStrategies.sol";

contract Medicis is WithStrategies {
	struct Grant {
		address recipient;
		uint256 grant;
	}

    uint256     public activation;
    uint256     public underlyingDecimals;
    uint256     public totalSupply;

    constructor(address _token, address _governance, address _guardian) {
        governance = _governance;
        management = _governance;
        guardian = _guardian;

        activation = block.timestamp;
        token = ERC20(_token);
        underlyingDecimals = IERC20Metadata(_token).decimals();
        depositLimit = type(uint256).max;
	}


    string      public constant API_VERSION = "0.3.0";
	function apiVersion() external pure returns (string memory) {
        return API_VERSION;
	}
	function name() external pure returns (string memory) {
        return "Medicis USDC";
	}
    function distributeRewards() internal {
    }
    function withdraw(uint256 shares, address recipient) external {
        revert("invalid widthdraw function");
    }
    function balanceOf(address donatore) public view returns (uint256) {
        return donatori.balanceOf(donatore);
    }

	/*******************************************************************************
    **	@notice
    **		Represents the value of one X shares in token.
    **  @param shares: The amount of share we want the value for.
    **  @return: The value of the share in token.
    *******************************************************************************/
	function _shareValue(uint256 shares) public view returns (uint256) {
	    if (totalSupply == 0) {
            return shares;
        }
	    return shares * totalAssets() / totalSupply;
	}
	
	/*******************************************************************************
    **	@notice
    **		For a specific amount, resolve the number of corresponding shares.
    **  @param amount: The amount we want the shares for.
    **  @return: The corresponding shares in token.
    *******************************************************************************/
	function _amountToShares(uint256 amount) internal view returns (uint256) {
	    return amount * totalSupply / totalAssets();
	}

	/*******************************************************************************
    **	@notice
    **		Returns the price of one share of this vault. The value of your share
    **      would be YOUR_SHARE x PRICE_PER_SHARE.
    **  @return: The value of 1 share.
    *******************************************************************************/
	function pricePerShare() public view returns (uint256) {
	    if (totalSupply == 0) {
	        return 10 ** underlyingDecimals; // price of 1:1
	    } else {
		    return _shareValue(10 ** underlyingDecimals);
	    }
	}
	
	/*******************************************************************************
    **	@notice
    **		Issues `amount` Vault shares to `to`.
    **      Shares must be issued prior to taking on new collateral, or
    **      calculation will be wrong. This means that only *trusted* tokens
    **      (with no capability for exploitative behavior) can be used.
	**  @param to: The address which will receive the share
	**  @param amount: The underlying amount
    **  @return: The share
    *******************************************************************************/
	function _issueSharesForAmount(uint256 amount) internal returns (uint256) {
	    uint256 shares = 0;
	    uint256 _totalSupply = totalSupply; //HACK: Saves 2 SLOADs (~4000 gas)
	    
	    if (_totalSupply > 0) {
	        // Mint amount of shares based on what the Vault is managing overall
		    // NOTE: if sqrt(token.totalSupply()) > 1e39, this could potentially revert
		    shares = amount * _totalSupply / totalAssets();
	    } else {
		    shares = amount; // No existing shares, so mint 1:1
	    }
	    
	    totalSupply += shares;
    	return shares;
	}
		
	/*******************************************************************************
	**  @notice
	**  	Deposits `grant` `token`, issuing shares to `donatore`. If the
	**  	Vault is in Emergency Shutdown, deposits will not be accepted and this
	**  	call will fail.
	**  @dev
	**  	Measuring quantity of shares to issues is based on the total
	**  	outstanding debt that this contract has ("expected value") instead
	**  	of the total balance sheet it has ("estimated value") has important
	**  	security considerations, and is done intentionally. If this value were
	**  	measured against external systems, it could be purposely manipulated by
	**  	an attacker to withdraw more assets than they otherwise should be able
	**  	to claim by redeeming their shares.
	**  	On deposit, this means that shares are issued against the total amount
	**  	that the deposited capital can be given in service of the debt that
	**  	Strategies assume. If that number were to be lower than the "expected
	**  	value" at some future point, depositing shares via this method could
	**  	entitle the depositor to *less* than the deposited value once the
	**  	"realized value" is updated from further reports by the Strategies
	**  	to the Vaults.
	**  @param donatore
	**      The address responsible of a grant
	**  @param grant
	**  	The amount of token the donatore wants to stake
	**  @param grants
	**  	Repartition of the grants for each recipient
	**  @return The issued ERC-721
    *******************************************************************************/
    function deposit(address donatore, Grant[] memory grants) external returns (uint256) {
        require(emergencyShutdown == false, "emergency shutdown enabled");

        uint256 amount = 0;
    	uint256 numberOfGrants = grants.length;
        for (uint256 i = 0; i < numberOfGrants; i++) {
			amount += grants[i].grant;
        }

        require(totalAssets() + amount <= depositLimit, "above limit"); // Ensure we are not overflowing
        require(amount > 0, "invalid deposit"); // Ensure we are depositing something

        uint256 tokenID = _deposit(donatore, amount, grants);
        
        return tokenID;
    }

    /*******************************************************************************
    **	@notice
    **		Mint a new NFT or update an existing one for this donatore and set it's
    **      NFT metadata.
    **      This also checks that the grantValue match the actual grants (revert 
    **      otherwise).
	**  @param donatore: The address responsible of a grant
	**  @param grants: Repartition of the grants for each recipient
    **  @return: The ID of the new token
    *******************************************************************************/
    function _deposit(address donatore, uint256 amount, Grant[] memory grants) internal returns (uint256) {
        uint256 numberOfGrants = grants.length;
		require(numberOfGrants <= maxGrants, "Above maxGrants");
		
		uint256 tokenID = donatori.getDonatorForAddress(donatore);
		uint256 totalShares = 0;
		if (tokenID == 0) {
		    tokenID = donatori.mint(donatore);
		    donatori.setDonatorForAddress(donatore, tokenID);
		}

        for (uint256 i = 0; i < numberOfGrants; i++) {
            address to = grants[i].recipient;
            uint256 shareForTo = _issueSharesForAmount(grants[i].grant);
            donatori.pushBeneficiario(tokenID, to);
            donatori.incGrantForBeneficiario(tokenID, to, grants[i].grant);
            totalShares += shareForTo;
            require(beneficiari.populate(donatore, grants[i].recipient, grants[i].grant, shareForTo) > 0, "invalid nft");
            require(token.transferFrom(msg.sender, address(this), grants[i].grant));
        }
        donatori.incGrant(tokenID, amount);
        donatori.incShare(tokenID, totalShares);
		require(donatori.getBeneficiariLen(tokenID) <= maxGrants, "Above maxGrants");
		return tokenID;
    }

    /* WITHDRAW */
    function withdraw(address recipient, Grant[] memory grants) external returns (uint256) {
        address donatore = msg.sender;
    	uint256 numberOfGrants = grants.length;
		uint256 amountToWithdraw = 0;

        for (uint256 i = 0; i < numberOfGrants; i++) {
            if (donatore == grants[i].recipient) {
                amountToWithdraw += _withdrawPosition(donatore, grants[i].grant, donatori.getDonatorForAddress(donatore), amountToWithdraw);
            } else {
                amountToWithdraw += _decreatePosition(donatore, grants[i].recipient, grants[i].grant, donatori.getDonatorForAddress(donatore), amountToWithdraw);
            }
        }
        //TODO: CHECK qu'il y ai assez de token dans le contrat
        token.transfer(recipient, amountToWithdraw);

        return amountToWithdraw;
    }

    /*******************************************************************************
    **	@dev
    **		If the donatore is the beneficiario, the users wants to reduce it's
    **      own position. We are not using the grant but the share, as a standard
    **      vault : you a withdrawing a specific share.
    *******************************************************************************/
    function _withdrawPosition(address donatore, uint256 shareToWithdraw, uint256 tokenID, uint256 alreadyWithdrawed) internal returns (uint256) {
        uint256 totalGrantForBeneficiario = donatori.getBeneficiarioGrant(donatore, donatore);
        uint256 totalSharesForBeneficiario = getShareForBeneficiario(donatore, donatore);
        require(totalSharesForBeneficiario > 0);
        if (shareToWithdraw > totalSharesForBeneficiario) {
            shareToWithdraw = totalSharesForBeneficiario;
        }

        uint256 grantToWithdraw = shareToWithdraw * (totalAssets() - alreadyWithdrawed) / (totalSupply);
        uint256 grantToWithdrawFromPosition = totalGrantForBeneficiario;

        //Decreasing the user's position
        if (donatori.getBeneficiarioGrant(tokenID, donatore) >= grantToWithdraw) {
            grantToWithdrawFromPosition = grantToWithdraw;
        }
        donatori.withdrawPosition(tokenID, donatore, grantToWithdrawFromPosition, shareToWithdraw);
        
        require(beneficiari.unpopulate(donatore, donatore, grantToWithdrawFromPosition, shareToWithdraw) > 0, "!invalidNFT");
        totalSupply -= shareToWithdraw;
        return (grantToWithdraw);
	}

    /*******************************************************************************
    **	@dev
    **		In order to be able to make only one Transfer TX at the end, we need
    **      to reproduce the `_shareValue` function with a slight edit : we need
    **      to reduce `totalAssets()` by the number of token computed from the
    **      previous beneficiario withdraw. Otherwise, the shareValue will be
    **      wrong for the next beneficiario.
    *******************************************************************************/
    function _decreatePosition(address donatore, address beneficiario, uint256 grantToWithdraw, uint256 tokenID, uint256 alreadyWithdrawed) internal returns (uint256) {
        //1. Check si l'adresse demandée est dans la liste des beneficiario
        uint256 totalGrantForBeneficiario = donatori.getBeneficiarioGrant(donatore, beneficiario);
        require(totalGrantForBeneficiario > 0);
        uint256 totalSharesForBeneficiario = getShareForBeneficiario(donatore, beneficiario);
        require(totalSharesForBeneficiario > 0);
        
        //2. Si l'utilisateur demande a retirer plus que la grant actuel, retirer la grant actuel
        if (grantToWithdraw > totalGrantForBeneficiario) {
            grantToWithdraw = totalGrantForBeneficiario;
        }

        uint256 shareToWithdraw = grantToWithdraw * totalSharesForBeneficiario / totalGrantForBeneficiario;
        uint256 grantValue = grantToWithdraw * (totalAssets() - alreadyWithdrawed) / (totalSupply);
        uint256 shareForBeneficiario = 0;
        if (grantValue >= grantToWithdraw) {
            shareForBeneficiario = grantValue - grantToWithdraw;
        }

        donatori.withdrawPosition(tokenID, beneficiario, grantToWithdraw, shareToWithdraw);
        require(beneficiari.unpopulate(
            donatore,
            beneficiario,
            grantToWithdraw,
            shareToWithdraw
        ) > 0, "!invalidNFT");

        uint256 scaledSharesForBeneficiario = beneficiari.shareValue(beneficiario, shareForBeneficiario);
        _setBeneficiari(beneficiario, scaledSharesForBeneficiario, alreadyWithdrawed);
        totalSupply -= (shareToWithdraw - shareForBeneficiario);
        
        return (grantToWithdraw);
	}

    function _setBeneficiari(address beneficiario, uint256 share, uint256 alreadyWithdrawed) internal {
		uint256 tokenID = donatori.getDonatorForAddress(beneficiario);
		if (tokenID == 0) {
		    tokenID = donatori.mint(beneficiario);
		    donatori.setDonatorForAddress(beneficiario, tokenID);
		}

        uint256 grant = share * (totalAssets() - alreadyWithdrawed) / (totalSupply);
        donatori.incGrantForBeneficiario(tokenID, beneficiario, grant);

        require(beneficiari.populate(beneficiario, beneficiario, grant, share) > 0, "invalid nft");
    }

    /* HARVEST */
    function harvest(uint256 amount) external returns (uint256) {
        uint256 beneficiarioGrants = beneficiari.getScaledShares(msg.sender);
        require(beneficiarioGrants > 0, "no grant");
        uint256 beneficiarioShares = beneficiari.getShares(msg.sender);
        require(beneficiarioShares > 0, "no share");

        uint256 grantAsShare = _shareValue(beneficiarioGrants);
        require(grantAsShare > beneficiarioShares, "nothing to harvest");
        uint256 amountToHarvest = grantAsShare - beneficiarioShares;

        uint256 amountToKeep = 0;
        if (amount < amountToHarvest) {
            amountToKeep = amountToHarvest - amount;
        } else if (amount >= amountToHarvest) {
            amount = amountToHarvest;
        }
        
        beneficiari.onHarvest(msg.sender, _amountToShares(amount));
        if (amountToKeep > 0) {
            _setBeneficiari(msg.sender, _amountToShares(amountToKeep), 0);
        }
        token.transfer(msg.sender, amount);
        return (amountToHarvest);
    }

    /*******************************************************************************
    **	@notice
    **		For a specific donatore, find the share for a beneficiario
    **  @return: The amount of share for this beneficiario.
    *******************************************************************************/
	function getShareForBeneficiario(address donatore, address beneficiario) public view returns (uint256) {
	    return beneficiari.getShareFromDonatore(donatore, beneficiario);
	}

    /*******************************************************************************
	**	@notice
	**       Reports the amount of assets the calling Strategy has free (usually in
	**       terms of ROI).
	**       The performance fee is determined here, off of the strategy's profits
	**       (if any), and sent to governance.
	**       The strategist's fee is also determined here (off of profits), to be
	**       handled according to the strategist on the next harvest.
	**       This may only be called by a Strategy managed by this Vault.
	**   @dev
	**       For approved strategies, this is the most efficient behavior.
	**       The Strategy reports back what it has free, then Vault "decides"
	**       whether to take some back or give it more. Note that the most it can
	**       take is `gain + _debtPayment`, and the most it can give is all of the
	**       remaining reserves. Anything outside of those bounds is abnormal behavior.
	**       All approved strategies must have increased diligence around
	**       calling this function, as abnormal behavior could become catastrophic.
	**   @param gain
	**       Amount Strategy has realized as a gain on it's investment since its
	**       last report, and is free to be given back to Vault as earnings
	**   @param loss
	**       Amount Strategy has realized as a loss on it's investment since its
	**       last report, and should be accounted for on the Vault's balance sheet
	**   @param _debtPayment
	**       Amount Strategy has made available to cover outstanding debt
	**   @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
	*******************************************************************************/
	function report(uint256 gain, uint256 loss, uint256 _debtPayment) external onlyActivated(msg.sender) returns (uint256) {
		require(token.balanceOf(msg.sender) >= gain + _debtPayment, "lie about available to withdraw");
		if (loss > 0) {
			_reportLoss(msg.sender, loss);
		}
		_assessFees(msg.sender, gain);
    	strategies[msg.sender].totalGain += gain;

		uint256 debt = _debtOutstanding(msg.sender);
    	uint256 debtPayment = Math.min(_debtPayment, debt);

    	if (debtPayment > 0) {
			strategies[msg.sender].totalDebt -= debtPayment;
			totalDebt -= debtPayment;
			debt -= debtPayment;
		}
    	uint256 credit = _creditAvailable(msg.sender);
		if (credit > 0) {
			strategies[msg.sender].totalDebt += credit;
			totalDebt += credit;
		}
		uint256 totalAvail = gain + debtPayment;
		if (totalAvail < credit) {
			require(token.transfer(msg.sender, credit - totalAvail), "err transfer");
		} else if (totalAvail > credit) {
			require(token.transferFrom(msg.sender, address(this), totalAvail - credit), "err transfer");
		}

		strategies[msg.sender].lastReport = block.timestamp;
		lastReport = block.timestamp;

		emit StrategyReported(
			msg.sender,
			gain,
			loss,
			strategies[msg.sender].totalGain,
			strategies[msg.sender].totalLoss,
			strategies[msg.sender].totalDebt,
			credit,
			strategies[msg.sender].debtRatio
		);

		if (strategies[msg.sender].debtRatio == 0 || emergencyShutdown) {
			return Strategy(msg.sender).estimatedTotalAssets();
		}
		return debt;
	}

	function _assessFees(address strategy, uint256 gain) internal {
        uint256 totalFees = gain * strategies[strategy].performanceFee / MAX_BPS;
        if (totalFees > 0) {
		    uint256 share = _issueSharesForAmount(totalFees);
            uint256 governanceFees = share * managementFee / MAX_BPS;
            uint256 performanceFee = share - governanceFees;
            if (governanceFees > 0) {
                _setBeneficiari(rewards, governanceFees, 0);
            }
            if (performanceFee > 0) {
                _setBeneficiari(strategy, performanceFee, 0);
            }
        }
	}

}