// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title DiplomeData
 * @dev Librairie (ou simple définitions) contenant les structures et l'énumération d'acteurs
 */
library DiplomeData {
    // Type d'acteur pour distinguer une adresse
    enum ActorType { None, Establishment, Company, Student }

    /**
     * @dev Informations sur l'établissement d'enseignement supérieur
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
     */
    struct Diplome {
        uint256 idDiplome;       // PK
        uint256 idTitulaire;     // ID_Etudiant
        string nomEtablissement; // Nom complet de l'établissement
        uint256 idEES;           // Lien vers l'établissement
        string pays;
        string typeDiplome; 
        string specialite;
        string mention;
        string dateObtention;
        bool exists; // Pour vérifier l'existence
    }
    
}
