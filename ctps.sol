pragma solidity ^0.4.24;

/// @title CTPS
/// @author Makhles R. Lange

// Carteira de Trabalho e Previdência Social
contract CTPS {
    address private empregado;

    function CTPS() public {
        empregado = msg.sender;
    }

}