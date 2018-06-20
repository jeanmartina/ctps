pragma solidity ^0.4.24;

/// @title CTPS
/// @author Makhles R. Lange

// Carteira de Trabalho e Previdência Social
contract CTPS {

    address private empregado;
    address private previdenciaSocial;
    address private dadosPessoais;

    address[] private solicitacoes;
    address[] private contratos;

    modifier onlyBy(address _quem) {
        require(_quem == msg.sender,
        "Acesso negado.");
        _;
    }

    // Evento que indica que um empregador deseja firmar um contrato com o dono da carteira
    event SolicitacaoContrato(address _contrato);

    // RF01 - 0x0c6c57e6e93725646e60bb23308a054e8870aa9c
    constructor(address _empregado, uint8 _dummy, address _dadosPessoais) public {
        previdenciaSocial = msg.sender;
        empregado = _empregado;
        dadosPessoais = _dadosPessoais;
    }

    // RF02 e RF03 - a alteração de dados poderá ser feita somente pela Previdência Social
    function alterarDadosPessoais(address _dadosPessoais) public onlyBy(previdenciaSocial) {
        dadosPessoais = _dadosPessoais;
    }

    // RF04
    function solicitarFirmaContrato(address _contrato) public {
        solicitacoes.push(_contrato);
        emit SolicitacaoContrato(_contrato);
    }

    // ---------
    // TESTES

    function obterDadosPessoais() public view onlyBy(previdenciaSocial) returns (address) {
        return dadosPessoais;
    }

}
