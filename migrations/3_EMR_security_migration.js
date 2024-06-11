const EMR_Securirty = artifacts.require("EMR_Security");

module.exports = function(deployer) {
  deployer.deploy(EMR_Securirty);
};