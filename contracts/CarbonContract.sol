pragma solidity ^0.4.18;

contract CarbonContract {

	mapping(uint=>mapping(address => bool)) approved; // Verifier decisions

	mapping (uint=>uint) deadline; // When the contract ends
	mapping (uint=>uint) fundSize;  // Total money in fund
	mapping (uint=>uint) currentSize;  // Current money in fund
	mapping (uint=>recipient[]) recipients; //  Who has received money from the fund
	mapping (uint=>bool) granted; // Whether the fund has ever successfully distributed money
	mapping (uint=>address[]) contributors; // Who has contributed to the funct
    mapping (uint=>mapping(address => uint)) contributions; // How much they've contributed to the fund
	mapping (uint=>string) conditions; // Condition under which the fund pays
	mapping (uint => address[]) verifiers; // List of verifiers of the contract
	mapping (uint => uint) verifierCount; // Counts verifiers
	mapping (uint => uint) totalSavings; // total savings of the recipients of a given contract

	struct recipient {
	    address rAddress;
	    uint individualSavings;
	}

	uint numCrowdFunds;

	function startCrowdFund(uint timeLimit, uint size, uint initialContribution, string conditions) public returns (uint crowdFundID) {
		uint id = ++numCrowdFunds;
		deadline[id] = block.number + timeLimit;
		fundSize[id] = size;
		currentSize[id] = initialContribution;
		contributions[id][msg.sender] = initialContribution;
		contributors[id].push(msg.sender);
	}

	function contributeToFund(uint id, uint contributorsHash) payable public returns (uint newSize)  {
		currentSize[id] += msg.value;
        fundSize[id] += currentSize[id];
		contributors[id].push(msg.sender);
		contributions[id][msg.sender] += msg.value;
		return newSize;
	}

	function contributeToSavings(uint id, uint savings) {
	    totalSavings[id] += savings;
	    for(uint i = 0; i < recipients[id].length; i++) {
	        if(recipients[id][i].rAddress == msg.sender) {
	            recipients[id][i].individualSavings += savings;   // unclear whether this should be passed as a function arg or as msg.value
	        }
	    }
	}

	function payToRecipients(uint id) public returns (bool amountPaid) {
        for(uint k = 0; k < recipients[id].length; k++) {
            address recipientAddress = recipients[id][k].rAddress;
            uint recipientIndividualSavings = recipients[id][k].individualSavings;
            uint recipientShare = ((100*recipientIndividualSavings)/totalSavings[id]) * fundSize[id];   // float/double division is not supported (may be buggy because of integer rounding)
            recipientShare /= 100;
            recipientAddress.send(recipientShare);
        }
	    return amountPaid;
	}

	function resolveFund(uint id) public returns (bool fundResolved) {
	    uint verifiedCount = 0;
		for(uint i = 0; i < verifiers[id].length; i++) {
			if(approved[id][verifiers[id][i]]) {
			    verifiedCount++;
			    if (verifiedCount > verifierCount[id]/2) {
			        granted[id] = true;
			    }
			}
		}

		if(block.number >= deadline[id] && !granted[id]) {
			// send back all the contributions
			for(uint j = 0; j < contributors[id].length; j++) {
				contributors[id][j].send(contributions[id][contributors[id][j]]);
			}
			return false;
		}

		else {
		    return payToRecipients(id);    // unclear if this function call is needed
		}
	}

	function clean(uint id) private {
		fundSize[id] = 0;
		currentSize[id] = 0;
	}
}
