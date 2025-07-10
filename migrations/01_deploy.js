const MBCPaymentSplitter = artifacts.require("MBCPaymentSplitter");

module.exports = async function(deployer, network, accounts) {
    
    const MBC_ADMIN = "0xb278E26776CD49f4fab88380ACCAB8A5f3639aD1"; // account 2
    const D5ART_ADMIN = "0x38F209165e2fFf0caEac0Ff31CF23257830f2ae5"; // account 4
    const D5ART_SUBADMIN = "0xc943e19A39B59a416Ecf19a12d541A3Fc7e8acB1"; //account 8
    const JV_WALLET = "0xa4a3cADC55b313a988d5dAEaF0F2253d52348758";  // account 7
    const PAYMENT_TOKEN = "0xAAd8f5F8c36A5CDa9840d9F6d893cAA64D72AA29";

    
    const BASIC_PRICE = web3.utils.toWei("10", "ether");     // 10 tokens
    const STANDARD_PRICE = web3.utils.toWei("15", "ether");  // 15 tokens
    const PREMIUM_PRICE = web3.utils.toWei("20", "ether");   // 20 tokens

    await deployer.deploy(
        MBCPaymentSplitter,
        MBC_ADMIN,
        D5ART_ADMIN,
        D5ART_SUBADMIN,
        JV_WALLET,
        PAYMENT_TOKEN,
        BASIC_PRICE,
        STANDARD_PRICE,
        PREMIUM_PRICE
    );

    
    const instance = await MBCPaymentSplitter.deployed();
    console.log("Contract deployed at:", instance.address);
    console.log("MBC Admin:", MBC_ADMIN);
    console.log("D5ART Admin:", D5ART_ADMIN);
    console.log("D5ART SubAdmin:", D5ART_SUBADMIN);
    console.log("JV Wallet:", JV_WALLET);
    console.log("PAYMENT_TOKEN:", PAYMENT_TOKEN);
};