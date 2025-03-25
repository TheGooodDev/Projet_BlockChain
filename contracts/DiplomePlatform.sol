// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DiplomeToken.sol";
import "./DiplomeNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./DiplomeData.sol";

/**
 * @title DiplomePlatform
 * @dev Contrat principal qui gère les enregistrements et interactions 
 *      (Etablissements, Entreprises, Etudiants, Diplômes), ainsi que 
 *      l'émission et la vérification d'un NFT "Diplome", et la gestion 
 *      de tokens ERC20 pour la rémunération et les frais.
 */
contract DiplomePlatform is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --------------------------------------------------------------------------
    // Références vers les contrats ERC20 (DiplomeToken) et ERC721 (DiplomeNFT)
    // --------------------------------------------------------------------------
    DiplomeToken private diplomeToken;
    DiplomeNFT private diplomeNFT;

    // --------------------------------------------------------------------------
    // Montants (en tokens) pour la rémunération et la vérification
    // --------------------------------------------------------------------------
    uint256 public constant EVALUATION_REWARD = 15 * 10**18; 
    uint256 public constant VERIFICATION_FEES = 10 * 10**18;

    // --------------------------------------------------------------------------
    // Énumération des rôles possibles
    // --------------------------------------------------------------------------
    enum ActorType { None, Establishment, Company }

    // --------------------------------------------------------------------------
    // Mappings pour stocker les données on-chain (structs définis dans DiplomeData)
    // Les mappings sont en 'private' afin d'éviter la génération automatique 
    // de getters qui peuvent alourdir la compilation.
    // --------------------------------------------------------------------------
    mapping(address => DiplomeData.EtablissementEnseignementSuperieur) private eesData;
    mapping(address => DiplomeData.Entreprise) private entrepriseData;
    mapping(uint256 => DiplomeData.Etudiant) private etudiants;  
    mapping(uint256 => DiplomeData.Diplome) private diplomes;  

    // Pour connaître le rôle d'une adresse (Etablissement, Entreprise ou aucun)
    mapping(address => ActorType) private actorTypes;

    // Ensemble des établissements autorisés à émettre (minter) des diplômes NFT
    EnumerableSet.AddressSet private establishmentSet;

    // --------------------------------------------------------------------------
    // Événements : volontairement réduits pour limiter l'usage de variables 
    // et éviter l'erreur "Stack too deep".
    // --------------------------------------------------------------------------
    event EstablishmentRegistered(address indexed establishment);
    event CompanyRegistered(address indexed company);
    event StudentRegistered(uint256 indexed idEtudiant);
    event DiplomeRegistered(uint256 indexed idDiplome);
    event StudentEvaluated(address indexed company, uint256 indexed studentId,string note);
    event DiplomaVerified(address indexed company);

    /**
     * @dev Constructeur. Initialise l'owner par défaut via Ownable().
     *      Définit les références vers DiplomeToken (ERC20) et DiplomeNFT (ERC721).
     * @param _tokenAddress Adresse du contrat DiplomeToken déployé
     * @param _nftAddress Adresse du contrat DiplomeNFT déployé
     */
    constructor(address _tokenAddress, address _nftAddress) Ownable(msg.sender) {
        diplomeToken = DiplomeToken(_tokenAddress);
        diplomeNFT = DiplomeNFT(_nftAddress);
    }

    // --------------------------------------------------------------------------
    //                      Fonctions d'enregistrement
    // --------------------------------------------------------------------------

    /**
     * @dev Enregistre un établissement d'enseignement supérieur (EES).
     *      L'appelant (msg.sender) devient 'Establishment' s'il ne l'était pas déjà.
     * @param _etab Struct DiplomeData.EtablissementEnseignementSuperieur avec
     *              toutes les informations de l'établissement.
     *
     * - Stocke les données dans eesData[msg.sender].
     * - Ajoute l'adresse dans establishmentSet pour l'autoriser à minter des diplômes.
     * - Émet un événement EstablishmentRegistered.
     */
    function registerEstablishment(
        DiplomeData.EtablissementEnseignementSuperieur calldata _etab
    ) external {
        require(actorTypes[msg.sender] == ActorType.None, "Actor already exists");

        // Stocke les infos de l'établissement
        eesData[msg.sender] = _etab;

        // Définit le rôle comme étant un établissement
        actorTypes[msg.sender] = ActorType.Establishment;
        establishmentSet.add(msg.sender);

        // Autorise cette adresse à minter des NFT Diplome
        diplomeNFT.grantMinterRole(msg.sender);

        emit EstablishmentRegistered(msg.sender);
    }

    /**
     * @dev Enregistre une entreprise. L'appelant (msg.sender) devient 'Company'.
     * @param _entreprise Struct DiplomeData.Entreprise avec
     *                    toutes les informations de l'entreprise.
     *
     * - Stocke les données dans entrepriseData[msg.sender].
     * - Émet un événement CompanyRegistered.
     */
    function registerCompany(
        DiplomeData.Entreprise calldata _entreprise
    ) external {
        require(actorTypes[msg.sender] == ActorType.None, "Actor already exists");

        entrepriseData[msg.sender] = _entreprise;
        actorTypes[msg.sender] = ActorType.Company;

        emit CompanyRegistered(msg.sender);
    }

    /**
     * @dev Enregistre un nouvel étudiant. Les informations sont passées sous forme de struct.
     * @param _student Struct DiplomeData.Etudiant contenant toutes les infos de l'étudiant.
     *
     * - Vérifie que l'ID_Etudiant n'est pas déjà enregistré.
     * - Stocke dans etudiants[_student.ID_Etudiant].
     * - Émet un événement StudentRegistered.
     */
    function registerStudent(
        DiplomeData.Etudiant calldata _student
    ) external {
        require(etudiants[_student.ID_Etudiant].ID_Etudiant == 0, "Student already exists");

        etudiants[_student.ID_Etudiant] = _student;

        emit StudentRegistered(_student.ID_Etudiant);
    }

    /**
     * @dev Enregistre un nouveau diplôme dans la variable 'diplomes', 
     *      pour un suivi on-chain supplémentaire (indépendamment du NFT).
     * @param _diplome Struct DiplomeData.Diplome contenant toutes les infos du diplôme.
     *
     * - Vérifie que ce diplomaId n'existe pas déjà dans le mapping.
     * - Émet un événement DiplomeRegistered.
     */
    function registerDiplome(
        DiplomeData.Diplome calldata _diplome
    ) external {
        require(diplomes[_diplome.ID_Diplome].ID_Diplome == 0, "Diploma already exists");

        diplomes[_diplome.ID_Diplome] = _diplome;

        emit DiplomeRegistered(_diplome.ID_Diplome);
    }

    // --------------------------------------------------------------------------
    //               Fonctions relatives aux Diplômes (NFT)
    // --------------------------------------------------------------------------

    /**
     * @dev Permet à un établissement (autorisé) de minter un NFT représentant un Diplôme.
     * @param _studentWallet Adresse du wallet de l'étudiant (destinataire du NFT).
     * @param _tokenURI URI contenant les métadonnées du diplôme (ex: IPFS).
     *
     * Seuls les Établissements (ActorType.Establishment) autorisés dans establishmentSet
     * peuvent exécuter cette fonction.
     */
    function mintDiplomaForStudent(address _studentWallet, string memory _tokenURI) external {
        require(actorTypes[msg.sender] == ActorType.Establishment, "Only establishment can mint");
        require(establishmentSet.contains(msg.sender), "Establishment not authorized");

        // Mint le NFT via le contrat DiplomeNFT
        diplomeNFT.mintDiplome(_studentWallet, _tokenURI);
    }

    // --------------------------------------------------------------------------
    //          Fonctions liées à l'évaluation et la vérification
    // --------------------------------------------------------------------------

    /**
    * @dev Permet à une entreprise d'évaluer un étudiant.
    *      - On précise l'ID de l'étudiant à évaluer.
    *      - On stocke la note (ou commentaire) dans etudiants[_idEtudiant].Evaluation.
    *      - L'entreprise reçoit EVALUATION_REWARD tokens en récompense.
    *
    * Émet l'événement StudentEvaluated, contenant l'adresse de l'entreprise,
    * l'ID de l'étudiant et la note donnée.
    *
    * @param _idEtudiant L'identifiant de l'étudiant (tel que défini lors du registerStudent)
    * @param _note       La note ou le commentaire attribué par l'entreprise (string)
    */
    function evaluateStudent(uint256 _idEtudiant, string calldata _note) external {
        require(actorTypes[msg.sender] == ActorType.Company, "Only a company can evaluate");

        require(etudiants[_idEtudiant].ID_Etudiant != 0, "Student does not exist");

        etudiants[_idEtudiant].Evaluation = _note;

        diplomeToken.rewardTokens(msg.sender, EVALUATION_REWARD);

        emit StudentEvaluated(msg.sender, _idEtudiant, _note);
    }


    /**
     * @dev Vérifie l'authenticité d'un diplôme (NFT). 
     *      En contrepartie, l'entreprise paie VERIFICATION_FEES tokens.
     * @param _tokenId ID du NFT (diplôme) à vérifier.
     *
     * L'entreprise doit au préalable faire "approve" de VERIFICATION_FEES 
     * sur DiplomeToken pour ce contrat. Ensuite, on prélève les tokens.
     * La fonction ownerOf(_tokenId) dans DiplomeNFT assure que le NFT existe.
     * Émet un événement DiplomaVerified.
     */
    function verifyDiploma(uint256 _tokenId) external {
        require(actorTypes[msg.sender] == ActorType.Company, "Only a company can verify");

        // On prélève 10 tokens à l'entreprise pour la vérification
        diplomeToken.transferFrom(msg.sender, address(this), VERIFICATION_FEES);

        diplomeNFT.ownerOf(_tokenId);

        emit DiplomaVerified(msg.sender);
    }

    // --------------------------------------------------------------------------
    //                         Fonctions d'aide
    // --------------------------------------------------------------------------

    /**
     * @dev Permet au propriétaire (owner) du contrat de retirer une quantité 
     *      de tokens (DPT) stockés dans ce contrat.
     * @param _amount Quantité de tokens à retirer.
     */
    function withdrawTokens(uint256 _amount) external onlyOwner {
        diplomeToken.transfer(msg.sender, _amount);
    }
}
