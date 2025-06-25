require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    sepolia: {
      provider: () => new HDWalletProvider({
        mnemonic: {
          phrase: process.env.MNEMONIC // 12 or 24-word phrase
        },
        providerOrUrl: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
        pollingInterval: 10000 // Optional: Adjust polling interval
      }),
      network_id: 11155111, // Sepolia's network ID
      gas: 5000000,         // Gas limit
      gasPrice: 10000000000, // 10 Gwei
      confirmations: 2,      // # of confirmations to wait
      timeoutBlocks: 200,    // # of blocks before timeout
      skipDryRun: true       // Skip dry run (recommended for testnets)
    }
  },
  compilers: {
    solc: {
      version: "0.8.21",    // Matches your pragma
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
};