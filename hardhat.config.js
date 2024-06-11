require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://mainnet.infura.io/v3/534490e9efe74119b3cc51a400f20076",
      },
    },
  },
};
