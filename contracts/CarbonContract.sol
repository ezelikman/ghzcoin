pragma solidity ^0.4.18;

contract CarbonContract {
	struct verifier {
		address source;
		string condition;
		bool approved;
	}

	struct crowdFund {
		uint deadline;
		uint fundSize;	// unclear whether a cap will be used to limit fund sizes
		uint currentSize;
		mapping(address => uint) contributions;
		address[] contributors;
		string[] conditions;	// unsure how to define conditions array vs verifiers array
		uint[] verifiers;
		address recipient;
		bool granted;
	}

	mapping(uint => crowdFund) CrowdFunds;
	mapping(uint => verifier) Verifiers;
	uint numCrowdFunds;

	function startCrowdFund(uint timeLimit, uint size, uint initialContribution, string[] conditions) public returns (uint crowdFundID) {
		uint cfID = ++numCrowdFunds;
		crowdFund c = CrowdFunds[cfID];
		c.deadline = block.number + timeLimit;
		c.fundSize = size;
		c.currentSize = initialContribution;
		c.contributions[msg.sender] = initialContribution;
		c.contributors[c.contributors.length] = msg.sender;
	}

	function contributeToFund(uint id, uint contributorsHash) public returns (uint currentSize) {
		crowdFund c = CrowdFunds[id];
		if(c.currentSize >= c.fundSize) {
			msg.sender.send(msg.value);
			return c.currentSize;
		}
		c.currentSize += msg.value;
		c.contributors[c.contributors.length] = msg.sender;
		return c.currentSize;
	}

	// TODO: add some mechanism for the fund to be verified by the "verifiers"

	function resolveFund(uint id) public returns (address fundRecipient) {
		crowdFund c = CrowdFunds[id];
		c.granted = true;
		for(uint i = 0; i < c.verifiers.length; i++) {
			if(!Verifiers[c.verifiers[i]].approved) {
				c.granted = false;
			}
		}

		if(!c.granted) {
			// send back all the contributions
			for(uint j = 0; j < c.contributors.length; j++) {
				c.contributors[j].send(c.contributions[c.contributors[j]]);
			}
		}

		else {
			c.recipient.send(c.fundSize);
		}
	}

	function clean(uint id) private {
		crowdFund c = CrowdFunds[id];
		c.fundSize = 0;
		c.currentSize = 0;
	}
}
