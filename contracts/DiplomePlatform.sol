// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DiplomeData.sol";
import "./DiplomeToken.sol";
import "./DiplomeNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title DiplomePlatform
 * @dev Contrat principal pour gérer la logique de l'application
 */
contract DiplomePlatform is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // -------------------------------------------------------------------
    // Référence vers le contrat ERC20 & NFT
    // -------------------------------------------------------------------
    DiplomeToken public diplomeToken;
    DiplomeNFT   public diplomeNFT;

    // -------------------------------------------------------------------
    // Frais en tokens
    // -------------------------------------------------------------------
    uint256 public constant EVALUATION_REWARD = 15 * 10**18; // 15 tokens
    uint256 public constant VERIFICATION_FEES = 10 * 10**18; // 10 tokens

    // -------------------------------------------------------------------
    // 1) Mappings et stockage
    //    On utilise la bibliothèque DiplomeData pour les types
    // -------------------------------------------------------------------

    // Type d'acteur pour distinguer l'adresse => enum ActorType
    mapping(address => DiplomeData.ActorType) public actorTypes;

    // Établissements : mapping adresse -> Establishment
    mapping(address => DiplomeData.Establishment) public establishments;

    // Entreprises : mapping adresse -> Company
    mapping(address => DiplomeData.Company) public companies;

    // Étudiants : mapping adresse -> Student
    mapping(address => DiplomeData.Student) public students;

    // Diplômes : mapping diplomaId -> Diplome
    mapping(uint256 => DiplomeData.Diplome) public diplomas;

    // Compteur pour générer un ID de diplôme unique
    uint256 public nextDiplomeId = 1; 

    // Pour traquer les adresses autorisées à minter (établissements validés)
    EnumerableSet.AddressSet private establishmentSet;

    // -------------------------------------------------------------------
    // 2) Events (optionnel, on peut aussi les mettre dans DiplomeData si on veut)
    // -------------------------------------------------------------------
    event EstablishmentRegistered(
        address indexed establishment, 
        uint256 indexed idEts, 
        string nom
    );

    event CompanyRegistered(
        address indexed company, 
        uint256 indexed idCompany, 
        string nom
    );

    event StudentRegistered(
        address indexed studentAddress, 
        uint256 indexed idStudent, 
        string nom
    );

    event DiplomeMinted(
        address indexed establishment, 
        address indexed studentWallet, 
        uint256 diplomeId
    );

    event StudentEvaluated(
        address indexed company, 
        address indexed student, 
        uint256 reward
    );

    event DiplomeVerified(
        address indexed company, 
        address indexed ownerOfDiplome, 
        uint256 feesPaid
    );

    // -------------------------------------------------------------------
    // 3) Constructeur
    // -------------------------------------------------------------------
    constructor(address _tokenAddress, address _nftAddress) Ownable(msg.sender) {
        diplomeToken = DiplomeToken(_tokenAddress);
        diplomeNFT   = DiplomeNFT(_nftAddress);
    }

    // -------------------------------------------------------------------
    // 4) Fonctions d'enregistrement
    // -------------------------------------------------------------------

    /**
     * @dev Enregistre un établissement d'enseignement
     */
    function registerEstablishment(
        uint256 _idEts,
        string memory _nom,
        string memory _typeEts,
        string memory _pays,
        string memory _adressePhysique,
        string memory _siteWeb,
        uint256 _idAgent
    ) 
        external 
    {
        require(
            actorTypes[msg.sender] == DiplomeData.ActorType.None, 
            "Already registered"
        );
        
        // Remplit la structure
        establishments[msg.sender] = DiplomeData.Establishment({
            idEls: _idEts,
            nomEtablissement: _nom,
            typeEtablissement: _typeEts,
            pays: _pays,
            adressePhysique: _adressePhysique,
            siteWeb: _siteWeb,
            idAgent: _idAgent,
            active: true
        });

        actorTypes[msg.sender] = DiplomeData.ActorType.Establishment;
        establishmentSet.add(msg.sender);

        // On donne le minter role dans le contrat NFT
        diplomeNFT.grantMinterRole(msg.sender);

        emit EstablishmentRegistered(msg.sender, _idEts, _nom);
    }

    /**
     * @dev Enregistre une entreprise
     */
    function registerCompany(
        uint256 _idEntreprise,
        string memory _nom,
        string memory _secteur,
        string memory _dateCreation,
        string memory _classificationTaille,
        string memory _pays,
        string memory _adressePhysique,
        string memory _courriel,
        string memory _telephone,
        string memory _siteWeb
    ) 
        external 
    {
        require(
            actorTypes[msg.sender] == DiplomeData.ActorType.None, 
            "Already registered"
        );

        companies[msg.sender] = DiplomeData.Company({
            idEntreprise: _idEntreprise,
            nom: _nom,
            secteur: _secteur,
            dateCreation: _dateCreation,
            classificationTaille: _classificationTaille,
            pays: _pays,
            adressePhysique: _adressePhysique,
            courriel: _courriel,
            telephone: _telephone,
            siteWeb: _siteWeb,
            active: true
        });

        actorTypes[msg.sender] = DiplomeData.ActorType.Company;

        emit CompanyRegistered(msg.sender, _idEntreprise, _nom);
    }

    /**
     * @dev Enregistre un étudiant
     */
    function registerStudent(
        uint256 _idEtudiant,
        string memory _nom,
        string memory _prenom,
        string memory _dateNaissance,
        string memory _sexe,
        string memory _nationalite,
        string memory _statutCivil,
        string memory _adressePhysique,
        string memory _courriel,
        string memory _telephone,
        string memory _section,
        string memory _sujetPFE,
        string memory _entrepriseStagePFE,
        string memory _nomEtPrenomMaitreDuStage,
        string memory _dateDebutStage,
        string memory _dateFinStage
    )
        external
    {
        require(
            actorTypes[msg.sender] == DiplomeData.ActorType.None, 
            "Already registered"
        );

        students[msg.sender] = DiplomeData.Student({
            idEtudiant: _idEtudiant,
            nom: _nom,
            prenom: _prenom,
            dateNaissance: _dateNaissance,
            sexe: _sexe,
            nationalite: _nationalite,
            statutCivil: _statutCivil,
            adressePhysique: _adressePhysique,
            courriel: _courriel,
            telephone: _telephone,
            section: _section,
            sujetPFE: _sujetPFE,
            entrepriseStagePFE: _entrepriseStagePFE,
            nomEtPrenomMaitreDuStage: _nomEtPrenomMaitreDuStage,
            dateDebutStage: _dateDebutStage,
            dateFinStage: _dateFinStage,
            evaluation: 0, 
            active: true
        });

        actorTypes[msg.sender] = DiplomeData.ActorType.Student;

        emit StudentRegistered(msg.sender, _idEtudiant, _nom);
    }

    // -------------------------------------------------------------------
    // 5) Gestion des Diplômes (NFT + struct interne)
    // -------------------------------------------------------------------

    /**
     * @dev Permet à un établissement de minter un diplôme NFT 
     *      + enregistrer la data du diplôme.
     */
    function mintDiplomeForStudent(
        address _studentWallet,
        uint256 _idTitulaire,
        uint256 _idEES,
        string memory _nomEtablissement,
        string memory _pays,
        string memory _typeDiplome,
        string memory _specialite,
        string memory _mention,
        string memory _dateObtention,
        string memory _tokenURI
    )
        external
    {
        require(
            actorTypes[msg.sender] == DiplomeData.ActorType.Establishment, 
            "Only establishment can mint"
        );
        require(
            establishmentSet.contains(msg.sender), 
            "Establishment not authorized"
        );

        uint256 currentDiplomeId = nextDiplomeId;
        nextDiplomeId++;

        // Stockage on-chain de la struct
        diplomas[currentDiplomeId] = DiplomeData.Diplome({
            idDiplome: currentDiplomeId,
            idTitulaire: _idTitulaire,
            nomEtablissement: _nomEtablissement,
            idEES: _idEES,
            pays: _pays,
            typeDiplome: _typeDiplome,
            specialite: _specialite,
            mention: _mention,
            dateObtention: _dateObtention,
            exists: true
        });

        // Mint du NFT
        diplomeNFT.mintDiplome(_studentWallet, _tokenURI);

        emit DiplomeMinted(msg.sender, _studentWallet, currentDiplomeId);
    }

    // -------------------------------------------------------------------
    // 6) Évaluation du stagiaire
    // -------------------------------------------------------------------

    function evaluateStudent(address _studentWallet, uint256 _note) external {
        require(
            actorTypes[msg.sender] == DiplomeData.ActorType.Company, 
            "Only a company can evaluate"
        );
        require(companies[msg.sender].active, "Company is not active");
        require(
            actorTypes[_studentWallet] == DiplomeData.ActorType.Student, 
            "The target is not a student"
        );
        require(
            students[_studentWallet].active, 
            "Student is not active"
        );

        // Met à jour la note de l'étudiant
        students[_studentWallet].evaluation = _note;

        // Récompense l'entreprise (15 tokens)
        diplomeToken.rewardTokens(msg.sender, EVALUATION_REWARD);

        emit StudentEvaluated(msg.sender, _studentWallet, EVALUATION_REWARD);
    }

    // -------------------------------------------------------------------
    // 7) Vérification du diplôme
    // -------------------------------------------------------------------

    function verifyDiplome(uint256 _tokenId) external {
        require(
            actorTypes[msg.sender] == DiplomeData.ActorType.Company, 
            "Only a company can verify"
        );
        require(companies[msg.sender].active, "Company is not active");

        // Paiement en tokens (approve préalable)
        diplomeToken.transferFrom(msg.sender, address(this), VERIFICATION_FEES);

        // Vérifie la propriété
        address ownerOfDiplome = diplomeNFT.ownerOf(_tokenId);

        emit DiplomeVerified(msg.sender, ownerOfDiplome, VERIFICATION_FEES);
    }

    // -------------------------------------------------------------------
    // 8) Fonctions d'aide
    // -------------------------------------------------------------------

    function getContractTokenBalance() external view returns (uint256) {
        return diplomeToken.balanceOf(address(this));
    }

    function withdrawTokens(uint256 _amount) external onlyOwner {
        diplomeToken.transfer(msg.sender, _amount);
    }

    /**
     * @dev Retourne les infos d'un diplôme
     */
    function getDiplomeInfo(uint256 _diplomeId) 
        external 
        view 
        returns (
            uint256 idDiplome,
            uint256 idTitulaire,
            string memory nomEtablissement,
            uint256 idEES,
            string memory pays,
            string memory typeDiplome,
            string memory specialite,
            string memory mention,
            string memory dateObtention,
            bool exists
        ) 
    {
        DiplomeData.Diplome memory d = diplomas[_diplomeId];
        require(d.exists, "Diplome does not exist");

        return (
            d.idDiplome,
            d.idTitulaire,
            d.nomEtablissement,
            d.idEES,
            d.pays,
            d.typeDiplome,
            d.specialite,
            d.mention,
            d.dateObtention,
            d.exists
        );
    }
}
