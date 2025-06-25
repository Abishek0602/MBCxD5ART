const MBCPaymentSplitter = artifacts.require("MBCPaymentSplitter");

module.exports = async function(deployer, network, accounts) {
    
    const MBC_ADMIN = accounts[0];
    const D5ART_ADMIN = accounts[1];
    const JV_WALLET = accounts[2];

    
    const BASIC_PRICE = web3.utils.toWei("0.1", "ether");
    const STANDARD_PRICE = web3.utils.toWei("0.2", "ether");
    const PREMIUM_PRICE = web3.utils.toWei("0.3", "ether");

    await deployer.deploy(
        MBCPaymentSplitter,
        MBC_ADMIN,
        D5ART_ADMIN,
        JV_WALLET,
        BASIC_PRICE,
        STANDARD_PRICE,
        PREMIUM_PRICE
    );

    
    const instance = await MBCPaymentSplitter.deployed();
    console.log("Contract deployed at:", instance.address);
    console.log("MBC Admin:", MBC_ADMIN);
    console.log("D5ART Admin:", D5ART_ADMIN);
    console.log("JV Wallet:", JV_WALLET);
};