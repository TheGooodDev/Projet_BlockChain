const hre = require("hardhat");

async function main() {
  // 1) On récupère la factory de DiplomeToken
  const TokenFactory = await hre.ethers.getContractFactory("DiplomeToken");
  // 2) On déploie
  const token = await TokenFactory.deploy();         // <-- renvoie directement un Contract
  await token.waitForDeployment();                   // <-- en Ethers v6, on utilise waitForDeployment()
  const tokenAddress = await token.getAddress();     // <-- récupère l'adresse du contrat
  console.log("DiplomeToken deployed to:", tokenAddress);

  // 3) On récupère la factory de DiplomeNFT
  const NFTFactory = await hre.ethers.getContractFactory("DiplomeNFT");
  // 4) On déploie
  const nft = await NFTFactory.deploy();
  await nft.waitForDeployment();
  const nftAddress = await nft.getAddress();
  console.log("DiplomeNFT deployed to:", nftAddress);

  // 5) On récupère la factory de DiplomePlatform
  const PlatformFactory = await hre.ethers.getContractFactory("DiplomePlatform");
  // 6) On déploie en passant l'adresse du Token et du NFT au constructeur
  const platform = await PlatformFactory.deploy(tokenAddress, nftAddress);
  await platform.waitForDeployment();
  const platformAddress = await platform.getAddress();
  console.log("DiplomePlatform deployed to:", platformAddress);
}

// Script runner
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
