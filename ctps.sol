pragma solidity ^0.4.24;

/// @title CTPS
/// @author Makhles R. Lange

// Contrato de Trabalho
contract Contrato {
    address public empregador;
    address public empregado;
    string private info;
    uint private dataAdmissao;
    uint private dataRescisao;

    modifier acesso(address _quem) {
        require(_quem == msg.sender, "Acesso negado.");
        _;
    }

    constructor(address _empregado, string _info) public {
        empregador = msg.sender;
        empregado = _empregado;
        info = _info;
    }

    function obterInfo() public view returns (string) {
        require(msg.sender == empregado || msg.sender == empregador, "Acesso negado.");
        return info;
    }
    
    function obterDataAdmissao() public view returns (uint) {
        require(msg.sender == empregado || msg.sender == empregador, "Acesso negado.");
        return dataAdmissao;
    }

    function firmar() public acesso(empregado) {
        dataAdmissao = now;
    }

    function obterDataRescisao() public view returns (uint) {
        require(msg.sender == empregado || msg.sender == empregador, "Acesso negado.");
        return dataRescisao;
    }

    function rescindir() public {
        require(msg.sender == empregado || msg.sender == empregador, "Acesso negado.");
        dataRescisao = now;
    }
}

// Carteira de Trabalho e Previdência Social
contract CTPS {

    address private empregado;
    address private previdenciaSocial;
    address private dadosPessoais;

    Contrato[] private solicitacoes;
    Contrato[] private contratos;

    modifier acesso(address _quem) {
        require(_quem == msg.sender, "Acesso negado.");
        _;
    }

    // Evento que indica que um empregador deseja firmar um contrato com o dono da carteira
    event SolicitacaoContrato(Contrato _contrato, uint _indice);

    // RF01 - 0x0c6c57e6e93725646e60bb23308a054e8870aa9c
    constructor(address _empregado, uint8 _dummy, address _dadosPessoais) public {
        previdenciaSocial = msg.sender;
        empregado = _empregado;
        dadosPessoais = _dadosPessoais;
    }

    // RF02 e RF03 - a alteração de dados poderá ser feita somente pela Previdência Social
    function alterarDadosPessoais(address _dadosPessoais) public acesso(previdenciaSocial) {
        dadosPessoais = _dadosPessoais;
    }

    // RF04
    function solicitarFirmaContrato(Contrato _contrato) public {
        uint indice = solicitacoes.push(_contrato) - 1;
        emit SolicitacaoContrato(_contrato, indice);
    }

    // RF05
    function firmarContrato(uint _indice) public acesso(empregado) {
        require (_indice < contratos.length, "Índice inválido.");
        contratos.push(solicitacoes[_indice]);
        contratos[contratos.length - 1].firmar();
        removerContrato(solicitacoes, _indice);
    }

    // RF05
    function rejeitarSolicitacao(uint _indice) public acesso(empregado) {
        removerContrato(solicitacoes, _indice);
    }

    // RF06
    function rescindirContrato(uint _indice) public acesso(empregado) {
        require (_indice < contratos.length, "Índice inválido.");
        contratos[contratos.length - 1].rescindir();
    }

    function removerContrato(Contrato[] storage _vetor, uint _indice) internal {
        for (uint i = _indice; i < _vetor.length - 1; i++) {
            _vetor[i] = _vetor[i+1];
        }
        _vetor.length--;
    }

    function obterInfo(uint _indice) public view acesso(empregado) returns (string) {
        require (_indice < contratos.length, "Índice inválido.");
        return contratos[_indice].obterInfo();
    }
    
    function obterDataAdmissao(uint _indice) public view acesso(empregado) returns (uint) {
        require (_indice < contratos.length, "Índice inválido.");
        return contratos[_indice].obterDataAdmissao();
    }

    function obterDataRescisao(uint _indice) public view acesso(empregado) returns (uint) {
        require (_indice < contratos.length, "Índice inválido.");
        return contratos[_indice].obterDataRescisao();
    }

    // ---------
    // TESTES

    function obterDadosPessoais() public view acesso(previdenciaSocial) returns (address) {
        return dadosPessoais;
    }

    function obterSolicitacoes() public view acesso(empregado) returns (uint) {
        return solicitacoes.length;
    }

    function obterSolicitacao(uint _indice) public view acesso(empregado) returns (address) {
        return solicitacoes[_indice];
    }
    
    function obterContratos() public view acesso(empregado) returns (uint) {
        return contratos.length;
    }
}