// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract DiplomeToken is ERC20, Ownable {
    
    // Taux de conversion : 0.01 ETH = 100 tokens
    // => 1 token = 0.0001 ETH
    uint256 public constant TOKENS_PER_ETHER = 10000; // Car 1 ETH = 10000 tokens (0.01 ETH = 100 tokens)
    

    constructor() ERC20("DiplomeToken", "DPT") Ownable(msg.sender) {
        // Le propriétaire (celui qui déploie) peut minter un stock initial
        _mint(msg.sender, 1_000_000 * 10**decimals()); 
    }

    /**
     * @notice Achat de tokens contre Ether.
     * 0.01 Ether = 100 tokens => 1 ETH = 10000 tokens
     */
    function buyTokens() external payable {
        require(msg.value > 0, "Send ETH to buy tokens");

        // Calcul du nombre de tokens en fonction du taux
        uint256 amountToBuy = msg.value * TOKENS_PER_ETHER;
        require(balanceOf(owner()) >= amountToBuy, "Not enough tokens in reserve");

        // Transfert des tokens depuis le owner vers l'acheteur
        _transfer(owner(), msg.sender, amountToBuy);
    }

    /**
     * @notice Retrait des Ethers accumulés sur le contrat par le propriétaire
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Distribution manuelle de tokens (par le propriétaire)
     * ex: pour récompenser une entreprise qui a évalué un stagiaire (15 tokens)
     */
    function rewardTokens(address _to, uint256 _amount) external onlyOwner {
        require(balanceOf(owner()) >= _amount, "Insufficient token balance in owner");
        _transfer(owner(), _to, _amount);
    }
}
