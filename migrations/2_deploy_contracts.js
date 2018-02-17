var CarbonContract = artifacts.require("./CarbonContrac.sol");
module.exports = function(deployer) {
  deployer.deploy(CarbonContract, 5, 100000, 10000, []);
};
