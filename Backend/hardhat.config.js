require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
     //mainnet
    lisk: {
      url: [process.env.LISK_RPC_URL],
      chainId:1135,
      accounts: [process.env.PRIVATE_KEY]
    },
         //testnet
    lisksepolia: {
      url:[process.env.SEPOLIA_RPC_URL] ,
      chainId: 4202,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
};