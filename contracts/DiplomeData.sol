// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


/**
 * @title DiplomeData
 * @dev Bibliothèque regroupant les structures de données pour le projet
 */
library DiplomeData {
    // Structure Entreprise
    struct Entreprise {
        uint256 ID_Entreprise;          
        string Nom;
        string Secteur;
        string Date_Creation;
        string Classification_Taille;
        string Pays;
        string Adresse;
        string Courriel;
        string Telephone;
        string Site_Web;
    }

    // Structure Diplôme
    struct Diplome {
        uint256 ID_Diplome;           
        uint256 ID_Titulaire;         
        string Nom_Etablissement;
        uint256 ID_EES;              
        string Pays;
        string Type_Diplome;
        string Specialite;
        string Mention;
        string Date_dobtention;
    }

    // Structure Etudiant
    struct Etudiant {
        uint256 ID_Etudiant;          
        string Nom;
        string Prenom;
        string Date_de_naissance;
        string Sexe;
        string Nationalite;
        string Statut_civil;
        string Adresse;
        string Courriel;
        string Telephone;
        string Section;
        string Sujet_PFE;
        string Entreprise_Stage_PFE;
        string NometPrenom_MaitreDuStage;
        string Date_debut_stage;
        string Date_fin_stage;
        string Evaluation;
    }

    // Structure Etablissement d'enseignement supérieur
    struct EtablissementEnseignementSuperieur {
        uint256 ID_ELS;              
        string Nom_Etablissement;
        string Type;                 
        string Pays;
        string Adresse;
        string Site_Web;
        uint256 ID_Agent;
    }
}
