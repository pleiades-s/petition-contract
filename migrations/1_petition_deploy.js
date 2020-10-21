const Petition = artifacts.require("Petition");

module.exports = function (deployer) {
  deployer.deploy(Petition);
};