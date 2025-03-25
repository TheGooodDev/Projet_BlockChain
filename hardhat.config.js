require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      viaIR: false
    }
  },
  networks: {
    besuLocal: {
      url: "http://localhost:8545",
      chainId: 1337,
      accounts: [
        "6649a4f58ffc81b64fb1894c07032198d01fa8432ecf1cda8385229e6ab3d390",
        "785dfcb5361a6e4c9d913dc7b6efe9c59acaa401689764b06cbaf3b7a5672ca3",
        "e0f4b12119e1f44acc2e2b41b70bba80e4fd45018a0d16ec93036cee1c8f5691"
      ]
    }
  }
};
