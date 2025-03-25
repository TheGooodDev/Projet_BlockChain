const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DiplomePlatform", function () {
    let token, nft, platform;
    let owner, addrEstablishment, addrCompany;
  
    before(async function () {
      // Récupère 3 signers (adresses) : 
      // - owner (le déployeur)
      // - addrEstablishment (l'établissement)
      // - addrCompany (l'entreprise)
      [owner, addrEstablishment, addrCompany] = await ethers.getSigners();
    });
  
    beforeEach(async function () {
        // 1) Déploie DiplomeToken depuis 'owner'
        const Token = await ethers.getContractFactory("DiplomeToken", owner);
        token = await Token.deploy();
        await token.waitForDeployment();
      
        // 2) Déploie DiplomeNFT depuis 'owner'
        const Nft = await ethers.getContractFactory("DiplomeNFT", owner);
        nft = await Nft.deploy();
        await nft.waitForDeployment();
      
        // 3) Déploie DiplomePlatform depuis 'owner'
        const Platform = await ethers.getContractFactory("DiplomePlatform", owner);
        platform = await Platform.deploy(
          await token.getAddress(), 
          await nft.getAddress()
        );
        await platform.waitForDeployment();
      
        // 4) => Donne le MINTER_ROLE au DiplomePlatform pour qu'il puisse minter
        const adminRole = await nft.DEFAULT_ADMIN_ROLE();
        await nft.connect(owner).grantRole(adminRole, await platform.getAddress());
        const minterRole = await nft.MINTER_ROLE();
        await nft.connect(owner).grantRole(minterRole, await platform.getAddress());
      
        // 5) => DiplomePlatform devient l'owner du DiplomeToken
        await token.connect(owner).transferOwnership(await platform.getAddress());

        // 6) => Transférez les tokens du 'owner' vers DiplomePlatform pour qu'il ait un solde suffisant
        const totalSupply = ethers.parseEther("1000000"); 
        await token.connect(owner).transfer(await platform.getAddress(), totalSupply);
        
      });
  
  
    it("should deploy all contracts correctly", async function () {
      // Récupération du nom du token (DiplomeToken)
      const name = await token.name();
      expect(name).to.equal("DiplomeToken");
  
      const nftName = await nft.name();
      expect(nftName).to.equal("DiplomeNFT");
    });

  it("should register an establishment (addrEstablishment)", async function () {
    // Construire l'objet struct pour l'établissement
    const etab = {
      ID_ELS: 1,
      Nom_Etablissement: "Universite X",
      Type: "Universite",
      Pays: "France",
      Adresse: "123 rue du savoir",
      Site_Web: "https://univ-x.fr",
      ID_Agent: 100
    };

    const establishmentAddr = await addrEstablishment.getAddress();

    await expect(
      platform.connect(addrEstablishment).registerEstablishment(etab)
    )
      .to.emit(platform, "EstablishmentRegistered")
      .withArgs(establishmentAddr);
  });

  it("should register a company (addrCompany)", async function () {
    // Construire l'objet struct pour la société
    const comp = {
      ID_Entreprise: 55,
      Nom: "Startup Y",
      Secteur: "Informatique",
      Date_Creation: "2025-01-01",
      Classification_Taille: "PME",
      Pays: "France",
      Adresse: "456 Rue Apple",
      Courriel: "[email protected]",
      Telephone: "0102030405",
      Site_Web: "https://startup-y.io"
    };

    // On appelle registerCompany depuis addrCompany
    await expect(
      platform.connect(addrCompany).registerCompany(comp)
    )
      .to.emit(platform, "CompanyRegistered")
      .withArgs(addrCompany.address);
  });

  it("should register a student", async function () {
    // 1) D'abord, registerEstablishment avec addrEstablishment
    //    pour qu'il soit un établissement valide
    const etab = {
      ID_ELS: 1,
      Nom_Etablissement: "Universite X",
      Type: "Universite",
      Pays: "France",
      Adresse: "123 rue du savoir",
      Site_Web: "https://univ-x.fr",
      ID_Agent: 100
    };
    await platform.connect(addrEstablishment).registerEstablishment(etab);

    // 2) On construit le struct de l'étudiant
    const student = {
      ID_Etudiant: 202,
      Nom: "Doe",
      Prenom: "John",
      Date_de_naissance: "01/01/2000",
      Sexe: "M",
      Nationalite: "Française",
      Statut_civil: "Célibataire",
      Adresse: "123 Main St",
      Courriel: "[email protected]",
      Telephone: "0606060606",
      Section: "Informatique",
      Sujet_PFE: "Blockchain",
      Entreprise_Stage_PFE: "Startup Z",
      NometPrenom_MaitreDuStage: "M. Smith",
      Date_debut_stage: "2025-03-01",
      Date_fin_stage: "2025-06-30",
      Evaluation: ""
    };

    // 3) Enregistrer un étudiant : 
    //    la fonction ne vérifie pas forcément le "role",
    //    mais on peut le faire depuis n'importe quel compte.
    await expect(platform.connect(addrEstablishment).registerStudent(student))
      .to.emit(platform, "StudentRegistered")
      .withArgs(202);
  });

  it("should register a diploma and mint an NFT for the student", async function () {
    // 1) Enregistre l'établissement
    const etab = {
      ID_ELS: 1,
      Nom_Etablissement: "Universite X",
      Type: "Universite",
      Pays: "France",
      Adresse: "123 rue du savoir",
      Site_Web: "https://univ-x.fr",
      ID_Agent: 100
    };
    await platform.connect(addrEstablishment).registerEstablishment(etab);

    // 2) Enregistre l'étudiant 
    const student = {
      ID_Etudiant: 202,
      Nom: "Doe",
      Prenom: "John",
      Date_de_naissance: "01/01/2000",
      Sexe: "M",
      Nationalite: "Française",
      Statut_civil: "Célibataire",
      Adresse: "123 Main St",
      Courriel: "[email protected]",
      Telephone: "0606060606",
      Section: "Informatique",
      Sujet_PFE: "Blockchain",
      Entreprise_Stage_PFE: "Startup Z",
      NometPrenom_MaitreDuStage: "M. Smith",
      Date_debut_stage: "2025-03-01",
      Date_fin_stage: "2025-06-30",
      Evaluation: ""
    };
    await platform.connect(addrEstablishment).registerStudent(student);

    // 3) Enregistre un Diplome on-chain (optionnel)
    const diplomeObj = {
      ID_Diplome: 1001,
      ID_Titulaire: 202,
      Nom_Etablissement: "Universite X",
      ID_EES: 1,
      Pays: "France",
      Type_Diplome: "Master",
      Specialite: "Informatique",
      Mention: "Bien",
      Date_dobtention: "2025-07-10"
    };
    await expect(platform.connect(addrEstablishment).registerDiplome(diplomeObj))
      .to.emit(platform, "DiplomeRegistered")
      .withArgs(1001);

    // 4) Mint du NFT : 
    //    L'adresse addrEstablishment est autorisée à minter
    const tokenUri = "ipfs://QmDiplomeHash";
    await platform.connect(addrEstablishment).mintDiplomaForStudent(
      owner.address,  // on donne le NFT au owner pour l'exemple
      tokenUri
    );

    // Vérifier la balance NFT du owner
    const nftBalance = await nft.balanceOf(owner.address);
    expect(nftBalance).to.equal(1);
  });

  it("should allow a company to evaluate a student and get rewarded with tokens", async function () {
    // 1) Enregistre l'établissement
    const etab = {
      ID_ELS: 1,
      Nom_Etablissement: "Universite X",
      Type: "Universite",
      Pays: "France",
      Adresse: "123 rue du savoir",
      Site_Web: "https://univ-x.fr",
      ID_Agent: 100
    };
    await platform.connect(addrEstablishment).registerEstablishment(etab);
  
    // 2) Enregistre la société (addrCompany)
    const comp = {
      ID_Entreprise: 55,
      Nom: "Startup Y",
      Secteur: "Informatique",
      Date_Creation: "2025-01-01",
      Classification_Taille: "PME",
      Pays: "France",
      Adresse: "456 Rue Apple",
      Courriel: "[email protected]",
      Telephone: "0102030405",
      Site_Web: "https://startup-y.io"
    };
    await platform.connect(addrCompany).registerCompany(comp);
  
    // 3) Enregistre l'étudiant ID=202
    const student = {
      ID_Etudiant: 202,
      Nom: "Doe",
      Prenom: "John",
      Date_de_naissance: "01/01/2000",
      Sexe: "M",
      Nationalite: "Française",
      Statut_civil: "Célibataire",
      Adresse: "123 Main St",
      Courriel: "[email protected]",
      Telephone: "0606060606",
      Section: "Informatique",
      Sujet_PFE: "Blockchain",
      Entreprise_Stage_PFE: "Startup Z",
      NometPrenom_MaitreDuStage: "M. Smith",
      Date_debut_stage: "2025-03-01",
      Date_fin_stage: "2025-06-30",
      Evaluation: ""
    };
  
    // Enregistrement de l'étudiant par l'établissement
    await platform.connect(addrEstablishment).registerStudent(student);
  
    // 4) Vérifier la balance de la société avant
    const balanceBefore = await token.balanceOf(addrCompany.address);
  
    // 5) Évaluer l'étudiant ID=202 avec note "20/20"
    await expect(
      platform.connect(addrCompany).evaluateStudent(202, "20/20")
    )
      .to.emit(platform, "StudentEvaluated")
      .withArgs(addrCompany.address, 202, "20/20");
  
    // 6) Vérifier la balance après
    const balanceAfter = await token.balanceOf(addrCompany.address);
    // EVALUATION_REWARD = 15 * 10^18
    const EVALUATION_REWARD = ethers.parseEther("15");
    expect(balanceAfter - balanceBefore).to.equal(EVALUATION_REWARD);
  });

  it("should allow a company to verify a diploma and pay 10 tokens", async function () {
    // 1) Enregistre l'établissement
    const etab = {
      ID_ELS: 1,
      Nom_Etablissement: "Universite X",
      Type: "Universite",
      Pays: "France",
      Adresse: "123 rue du savoir",
      Site_Web: "https://univ-x.fr",
      ID_Agent: 100
    };
    await platform.connect(addrEstablishment).registerEstablishment(etab);

    // 2) Enregistre la société (addrCompany)
    const comp = {
      ID_Entreprise: 55,
      Nom: "Startup Y",
      Secteur: "Informatique",
      Date_Creation: "2025-01-01",
      Classification_Taille: "PME",
      Pays: "France",
      Adresse: "456 Rue Apple",
      Courriel: "[email protected]",
      Telephone: "0102030405",
      Site_Web: "https://startup-y.io"
    };
    await platform.connect(addrCompany).registerCompany(comp);

    // 3) L'entreprise doit avoir 10 tokens pour vérifier
    await token.connect(platform).rewardTokens(addrCompany.address, ethers.parseEther("15"));

    // 3) L'entreprise approuve 10 tokens
    await token.connect(addrCompany).approve(platform.getAddress(), ethers.parseEther("10"));
    await token.connect(addrCompany).approve(platform.getAddress(), verificationFee);

    // 6) Appeler verifyDiploma(tokenId)
    //    Ici tokenId devrait être 1 si c'est le 1er minted, 
    //    mais on peut vérifier via un call NFT totalSupply ou un autre mécanisme. 
    await expect(platform.connect(addrCompany).verifyDiploma(1))
      .to.emit(platform, "DiplomaVerified")
      .withArgs(addrCompany.address); // event

    // 7) Vérif que la balance de addrCompany a baissé de 10 tokens
    const balance = await token.balanceOf(addrCompany.address);
    // Comme on lui a donné 15, elle devrait avoir 5 tokens restants
    expect(balance).to.equal(ethers.parseEther("5"));
  });
});
