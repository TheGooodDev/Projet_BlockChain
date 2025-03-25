// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    // Référence vers le contrat ERC20
    DiplomeToken public diplomeToken;

    // Référence vers le contrat NFT
    DiplomeNFT public diplomeNFT;

    // Frais en tokens
    uint256 public constant EVALUATION_REWARD = 15 * 10**18; // 15 tokens
    uint256 public constant VERIFICATION_FEES = 10 * 10**18; // 10 tokens

    // -----------------------------------------------------
    // 1) Définition des structures de données
    // -----------------------------------------------------

    // Type d'acteur pour distinguer une adresse
    enum ActorType { None, Establishment, Company, Student }

    /**
     * @dev Informations sur l'établissement d'enseignement supérieur
     * ID_ELS
     * Nom_Etablissement
     * Type
     * Pays
     * Adresse
     * Site_Web
     * ID_Agent
     */
    struct Establishment {
        uint256 idEls;
        string nomEtablissement;
        string typeEtablissement;  // Université, école, institut, etc.
        string pays;
        string adressePhysique;
        string siteWeb;
        uint256 idAgent;
        bool active;
    }

    /**
     * @dev Informations sur l'entreprise
     * ID_Entreprise
     * Nom
     * Secteur
     * Date_Creation
     * Classification_Taille
     * Pays
     * Adresse
     * Courriel
     * Téléphone
     * Site Web
     */
    struct Company {
        uint256 idEntreprise;
        string nom;
        string secteur;
        string dateCreation;
        string classificationTaille;
        string pays;
        string adressePhysique;
        string courriel;
        string telephone;
        string siteWeb;
        bool active;
    }

    /**
     * @dev Informations sur l'étudiant
     * ID_Etudiant
     * Nom
     * Prénom
     * Date de naissance
     * Sexe
     * Nationalité
     * Statut civil
     * Adresse
     * Courriel
     * Téléphone
     * Section
     * Sujet_PFE
     * Entreprise_Stage_PFE
     * NomEtPrenom_MaitreDuStage
     * Date_début_stage
     * Date_fin_stage
     * Evaluation
     */
    struct Student {
        uint256 idEtudiant;
        string nom;
        string prenom;
        string dateNaissance;
        string sexe;
        string nationalite;
        string statutCivil;
        string adressePhysique;
        string courriel;
        string telephone;
        string section;
        string sujetPFE;
        string entrepriseStagePFE;
        string nomEtPrenomMaitreDuStage;
        string dateDebutStage;
        string dateFinStage;
        uint256 evaluation; // Note (0-100) ou tout autre système
        bool active;
    }

    /**
     * @dev Informations sur le diplôme
     * ID_Diplome
     * ID_Titulaire
     * Nom_Etablissement
     * ID_EES
     * Pays
     * Type_Diplôme
     * Spécialité
     * Mention
     * Date d'obtention
     */
    struct Diploma {
        uint256 idDiplome;       // PK
        uint256 idTitulaire;     // ID_Etudiant
        string nomEtablissement; // Nom complet de l'établissement
        uint256 idEES;          // Lien vers l'établissement
        string pays;
        string typeDiplome; 
        string specialite;
        string mention;
        string dateObtention;
        bool exists; // Pour vérifier l'existence
    }

    // -----------------------------------------------------
    // 2) Stockage on-chain via mapping
    // -----------------------------------------------------

    // Chaque adresse peut représenter un établissement, une entreprise, ou un étudiant
    mapping(address => ActorType) public actorTypes;

    // Établissements : mapping adresse -> Establishment
    mapping(address => Establishment) public establishments;

    // Entreprises : mapping adresse -> Company
    mapping(address => Company) public companies;

    // Étudiants : mapping adresse -> Student
    mapping(address => Student) public students;

    // Diplômes : mapping diplomId -> Diploma
    mapping(uint256 => Diploma) public diplomas;
    uint256 public nextDiplomaId = 1; // Auto-increment

    // Pour traquer les adresses autorisées à minter (établissements validés)
    EnumerableSet.AddressSet private establishmentSet;

    // -----------------------------------------------------
    // 3) Évents
    // -----------------------------------------------------
    event EstablishmentRegistered(address indexed establishment, uint256 indexed idEts, string nom);
    event CompanyRegistered(address indexed company, uint256 indexed idCompany, string nom);
    event StudentRegistered(address indexed studentAddress, uint256 indexed idStudent, string nom);

    event DiplomaMinted(
        address indexed establishment, 
        address indexed studentWallet, 
        uint256 diplomaId
    );

    event StudentEvaluated(
        address indexed company, 
        address indexed student, 
        uint256 reward
    );

    event DiplomaVerified(
        address indexed company, 
        address indexed ownerOfDiploma, 
        uint256 feesPaid
    );

    // -----------------------------------------------------
    // 4) Constructeur
    // -----------------------------------------------------
    constructor(address _tokenAddress, address _nftAddress) Ownable(msg.sender) {
        diplomeToken = DiplomeToken(_tokenAddress);
        diplomeNFT = DiplomeNFT(_nftAddress);
    }

    // -----------------------------------------------------
    // 5) Fonctions d'enregistrement
    // -----------------------------------------------------

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
        require(actorTypes[msg.sender] == ActorType.None, "Already registered");
        
        establishments[msg.sender] = Establishment({
            idEls: _idEts,
            nomEtablissement: _nom,
            typeEtablissement: _typeEts,
            pays: _pays,
            adressePhysique: _adressePhysique,
            siteWeb: _siteWeb,
            idAgent: _idAgent,
            active: true
        });

        actorTypes[msg.sender] = ActorType.Establishment;
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
        require(actorTypes[msg.sender] == ActorType.None, "Already registered");

        companies[msg.sender] = Company({
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

        actorTypes[msg.sender] = ActorType.Company;

        emit CompanyRegistered(msg.sender, _idEntreprise, _nom);
    }

    /**
     * @dev Enregistre un étudiant (on peut l'associer à un wallet)
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
        require(actorTypes[msg.sender] == ActorType.None, "Already registered");

        students[msg.sender] = Student({
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
            evaluation: 0, // pas encore évalué
            active: true
        });

        actorTypes[msg.sender] = ActorType.Student;

        emit StudentRegistered(msg.sender, _idEtudiant, _nom);
    }

    // -----------------------------------------------------
    // 6) Gestion des Diplômes (NFT + struct interne)
    // -----------------------------------------------------

    /**
     * @dev Permet à un établissement (EES) de minter un diplôme NFT 
     *      et d'enregistrer les données de ce diplôme on-chain (struct Diploma).
     * @param _studentWallet L'adresse de l'étudiant (doit être déjà enregistré, ou pas obligatoire)
     * @param _idTitulaire ID de l'étudiant (hors-chain ou base interne)
     * @param _idEES ID de l'établissement
     * @param _nomEtablissement Nom de l'établissement
     * @param _pays Pays du diplôme
     * @param _typeDiplome Ex: "Licence", "Master", etc.
     * @param _specialite Ex: "Informatique"
     * @param _mention Ex: "Bien", "Très bien", ...
     * @param _dateObtention Date d'obtention
     * @param _tokenURI Le lien vers les métadonnées (IPFS) pour le NFT
     */
    function mintDiplomaForStudent(
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
        // Vérifier que l'appelant est bien un établissement
        require(actorTypes[msg.sender] == ActorType.Establishment, "Only establishment can mint");
        require(establishmentSet.contains(msg.sender), "Establishment not authorized");

        // On génère un nouvel ID de diplôme
        uint256 currentDiplomaId = nextDiplomaId;
        nextDiplomaId++;

        // Enregistrer la structure de données du diplôme on-chain
        diplomas[currentDiplomaId] = Diploma({
            idDiplome: currentDiplomaId,
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

        // Mint le NFT correspondant
        diplomeNFT.mintDiploma(_studentWallet, _tokenURI);

        emit DiplomaMinted(msg.sender, _studentWallet, currentDiplomaId);
    }

    // -----------------------------------------------------
    // 7) Évaluation du stagiaire
    // -----------------------------------------------------

    /**
     * @dev Évaluation d'un étudiant par l'entreprise
     *      L'entreprise reçoit 15 tokens en récompense
     * @param _studentWallet L'adresse du student à évaluer
     * @param _note La note ou l'appréciation (ex: 0-100)
     */
    function evaluateStudent(address _studentWallet, uint256 _note) external {
        require(actorTypes[msg.sender] == ActorType.Company, "Only a company can evaluate");
        require(companies[msg.sender].active, "Company is not active");
        require(actorTypes[_studentWallet] == ActorType.Student, "The target is not a student");
        require(students[_studentWallet].active, "Student is not active");

        // Mettre à jour l'évaluation dans la struct Student
        // On suppose qu'une seule évaluation ou on peut cumuler/faire la moyenne...
        students[_studentWallet].evaluation = _note;

        // L'entreprise reçoit 15 tokens => via le token contract (depuis owner du token)
        diplomeToken.rewardTokens(msg.sender, EVALUATION_REWARD);

        emit StudentEvaluated(msg.sender, _studentWallet, EVALUATION_REWARD);
    }

    // -----------------------------------------------------
    // 8) Vérification du diplôme
    // -----------------------------------------------------

    /**
     * @dev Vérification de l'authenticité d'un diplôme
     *      L'entreprise doit payer 10 tokens (approve préalable)
     */
    function verifyDiploma(uint256 _tokenId) external {
        require(actorTypes[msg.sender] == ActorType.Company, "Only a company can verify");
        require(companies[msg.sender].active, "Company is not active");

        // L'entreprise doit avoir fait "approve" de 10 tokens avant d'appeler cette fonction
        diplomeToken.transferFrom(msg.sender, address(this), VERIFICATION_FEES);

        // Logique on-chain: vérifier que le NFT existe, etc.
        address ownerOfDiploma = diplomeNFT.ownerOf(_tokenId);

        // Event => on sait qui a vérifié et qui est propriétaire du NFT
        emit DiplomaVerified(msg.sender, ownerOfDiploma, VERIFICATION_FEES);
    }

    // -----------------------------------------------------
    // 9) Fonctions d'aide
    // -----------------------------------------------------

    /**
     * @dev Récupération du solde de tokens du contrat 
     *      (s'il en reçoit via la vérification, etc.)
     */
    function getContractTokenBalance() external view returns (uint256) {
        return diplomeToken.balanceOf(address(this));
    }

    /**
     * @dev Retrait des tokens accumulés sur le contrat (par l'owner)
     */
    function withdrawTokens(uint256 _amount) external onlyOwner {
        diplomeToken.transfer(msg.sender, _amount);
    }

    // -----------------------------------------------------
    // 10) (Optionnel) Récupération d'infos sur un diplôme
    // -----------------------------------------------------

    /**
     * @dev Retourne les infos d'un diplôme stocké on-chain
     */
    function getDiplomaInfo(uint256 _diplomaId) 
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
        Diploma memory d = diplomas[_diplomaId];
        require(d.exists, "Diploma does not exist");
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
