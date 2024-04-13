// const IERC20 = artifacts.require("IERC20.sol");
const Example_contract = artifacts.require("Example.sol");

module.exports = async function (deployer, network, accounts) {

  await deployer.deploy(Example_contract, { from: accounts[0] });
  const example_contract = await Example_contract.deployed();
  // let owner = await example_contract.owner();

};
