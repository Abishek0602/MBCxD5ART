const TestToken = artifacts.require("TestToken");

module.exports = async function (deployer, network, accounts) {
  const initialSupply = "1000000000000000000000000"; // 1 million tokens with 18 decimals
  await deployer.deploy(TestToken, initialSupply);

  const instance = await TestToken.deployed();
  console.log("Contract deployed at:", instance.address);
};
