pragma solidity ^0.4.24;

/// @title CTPS
/// @author Makhles R. Lange

// Contrato de Trabalho
contract Contrato {
    enum TipoLicenca { MATERNIDADE, PATERNIDADE, CASAMENTO, OBITO, MILITAR }
    struct Licenca {
        TipoLicenca tipo;
        uint inicio;
        uint termino;
    }
    struct Ferias {
        uint inicio;
        uint termino;
    }
    address public empregador;
    address public empregado;
    string private info;
    uint private dataAdmissao = 0;
    uint private dataRescisao = 0;
    Licenca[] private licencas;
    Ferias[] private ferias;

    modifier acesso(address _quem) {
        require(_quem == msg.sender, "Acesso negado.");
        _;
    }

    constructor(address _empregado, string _info, address _empregador) public {
        empregado = _empregado;
        empregador = _empregador;
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
        require(dataAdmissao == 0, "Este contrato já foi firmado.");
        dataAdmissao = block.timestamp;
    }

    function obterDataRescisao() public view returns (uint) {
        require(msg.sender == empregado || msg.sender == empregador, "Acesso negado.");
        return dataRescisao;
    }

    function rescindir() public {
        require(msg.sender == empregado || msg.sender == empregador, "Acesso negado.");
        require(dataAdmissao != 0, "Este contrato ainda não foi firmado.");
        dataRescisao = block.timestamp;
    }

    // RF07
    function adicionarLicenca(uint _tipo, uint _inicio, uint _termino) public {
        require(msg.sender == empregador, "Acesso negado.");
        require(_tipo <= uint(TipoLicenca.MILITAR), "Tipo de licença inexistente.");
        require(_termino > _inicio, "O término do período de licença deve ocorrer após o seu início.");
        Licenca memory licenca = Licenca(TipoLicenca(_tipo), _inicio, _termino);
        licencas.push(licenca);
    }

    // RF09
    function adicionarFerias(uint _inicio, uint _termino) public {
        require(msg.sender == empregador, "Acesso negado.");
        require(_termino > _inicio, "O término das férias deve ocorrer após o seu início.");
        Ferias memory periodoFerias = Ferias(_inicio, _termino);
        ferias.push(periodoFerias);
    }
}

// Carteira de Trabalho e Previdência Social
contract CTPS {

    address private empregado;
    address private previdenciaSocial;
    address private dadosPessoais;

    address[] private solicitacoes;
    address[] private contratos;

    modifier acesso(address _quem) {
        require(_quem == msg.sender, "Acesso negado.");
        _;
    }

    // Evento que indica que um empregador deseja firmar um contrato com o dono da carteira.
    event SolicitacaoContrato(uint _indice);

    // Evento que indica que um novo contrato foi firmado pelo empregado e que deve
    // ser ouvido pelo empregador para que este possa adicionar licenças e períodos de férias.
    event ContratoFirmado(address _contrato);

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
    function solicitarContrato(string _info) public {
        Contrato c = new Contrato(empregado, _info, msg.sender);
        uint indice = solicitacoes.push(c) - 1;
        emit SolicitacaoContrato(indice);
    }

    // RF05
    function firmarContrato(uint _indice) public acesso(empregado) {
        require (_indice < solicitacoes.length, "Índice inválido.");
        Contrato c = Contrato(solicitacoes[_indice]);
        c.firmar();
        contratos.push(c);
        removerElemento(solicitacoes, _indice);
        emit ContratoFirmado(contratos[contratos.length-1]);
    }
    

    // RF05
    function rejeitarSolicitacao(uint _indice) public acesso(empregado) {
        removerElemento(solicitacoes, _indice);
    }

    // RF06
    function rescindirContrato(uint _indice) public acesso(empregado) {
        require (_indice < contratos.length, "Índice inválido.");
        Contrato c = Contrato(contratos[_indice]);
        c.rescindir();
    }

    function removerElemento(address[] storage _vetor, uint _indice) internal {
        for (uint i = _indice; i < _vetor.length - 1; i++) {
            _vetor[i] = _vetor[i+1];
        }
        _vetor.length--;
    }

    function obterInfo(uint _indice) public view acesso(empregado) returns (string) {
        require (_indice < contratos.length, "Índice inválido.");
        Contrato c = Contrato(contratos[_indice]);
        return c.obterInfo();
    }
    
    function obterDataAdmissao(uint _indice) public view acesso(empregado) returns (uint) {
        require (_indice < contratos.length, "Índice inválido.");
        Contrato c = Contrato(contratos[_indice]);
        return c.obterDataAdmissao();
    }

    function obterDataRescisao(uint _indice) public view acesso(empregado) returns (uint) {
        require (_indice < contratos.length, "Índice inválido.");
        Contrato c = Contrato(contratos[_indice]);
        return c.obterDataRescisao();
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