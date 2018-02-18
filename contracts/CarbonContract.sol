pragma solidity ^0.4.18;

contract CarbonContract {

	mapping(uint=>mapping(address => bool)) approved; // Verifier decisions
	
	mapping (uint=>uint) deadline; // When the contract ends
	mapping (uint=>uint) fundSize;  // Total money in fund
	mapping (uint=>uint) currentSize;  // Current money in fund
	mapping (uint=>address) recipient; //  Who has received money from the fund
	mapping (uint=>bool) granted; // Whether the fund has ever successfully distributed money
	mapping (uint=>address[]) contributors; // Who has contributed to the funct
    mapping (uint=>mapping(address => uint)) contributions; // How much they've contributed to the fund
	mapping (uint=>string) conditions; // Condition under which the fund pays
	mapping (uint => address[]) verifiers; // List of verifiers of the contract
	mapping (uint => uint) verifierCount; // Counts verifiers
	
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

	// TODO: add some mechanism for the fund to be verified by the "verifiers"
	
	function payToRecipients(uint id) public returns (bool amountPaid) {
	    return amountPaid;
	}

	function resolveFund(uint id) public returns (address fundRecipient) {
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
		}

		else {
			recipient[id].send(fundSize[id]);
		}
	}

	function clean(uint id) private {
		fundSize[id] = 0;
		currentSize[id] = 0;
	}
}