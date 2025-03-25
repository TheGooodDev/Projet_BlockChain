pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DiplomeNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private _tokenIdCounter;

    constructor() ERC721("DiplomeNFT", "DPLM") {
        // The deployer is granted the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Permet d'accorder à un établissement le droit de minter un NFT
     */
    function grantMinterRole(address _establishment)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, _establishment);
    }

    /**
     * @dev Création (mint) d'un diplôme NFT
     * @param recipient : l'adresse qui recevra le NFT (peut être l'adresse de l'étudiant)
     * @param tokenURI_ : URI (IPFS par exemple) contenant les métadonnées
     */
    function mintDiploma(address recipient, string memory tokenURI_)
        external
        onlyRole(MINTER_ROLE)
    {
        _tokenIdCounter++;
        uint256 newDiplomaId = _tokenIdCounter;

        _safeMint(recipient, newDiplomaId);
        _setTokenURI(newDiplomaId, tokenURI_);
    }

    /**
     * @dev Necessary override to reconcile multiple parents
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
