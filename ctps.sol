pragma solidity ^0.4.24;

/// @title CTPS
/// @author Makhles R. Lange

// Contrato de Trabalho
contract Contrato {
    enum TipoLicenca { MATERNIDADE, PATERNIDADE, CASAMENTO, OBITO, MILITAR, NAO_REMUNERADA }
    struct Licenca {
        TipoLicenca tipo;
        uint inicio;
        uint termino;
    }
    struct Ferias {
        uint inicio;
        uint termino;
    }
    struct Afastamento {
        string motivo;
        uint inicio;
        uint termino;
        bool integra;
    }
    
    address public empregador;
    address public ctps;
    address public inss;
    string private info;
    
    uint private dataAdmissao = 0;
    uint private dataRescisao = 0;
    
    Licenca[] private licencas;
    Ferias[] private ferias;
    Afastamento[] private afastamentos;

    constructor(address _ctps, string _info, address _empregador, uint8 _dummy, address _inss) public {
        ctps = _ctps;
        empregador = _empregador;
        info = _info;
        inss = _inss;
    }

    function obterInfo() public view returns (string) {
        require(msg.sender == ctps || msg.sender == empregador, "Acesso negado.");
        return info;
    }
    
    function obterDataAdmissao() public view returns (uint) {
        require(msg.sender == ctps || msg.sender == empregador, "Acesso negado.");
        return dataAdmissao;
    }

    function firmar() public {
        require(msg.sender == ctps, "Acesso negado.");
        require(dataAdmissao == 0, "Este contrato já foi firmado.");
        dataAdmissao = block.timestamp;
    }

    function obterDataRescisao() public view returns (uint) {
        require(msg.sender == ctps || msg.sender == empregador, "Acesso negado.");
        return dataRescisao;
    }

    function rescindir() public {
        require(msg.sender == ctps || msg.sender == empregador, "Acesso negado.");
        require(dataAdmissao != 0, "Este contrato ainda não foi firmado.");
        dataRescisao = block.timestamp;
    }

    // RF07
    function adicionarLicenca(uint _tipo, uint _inicio, uint _termino) public {
        require(msg.sender == empregador, "Acesso negado.");
        require(_tipo <= uint(TipoLicenca.NAO_REMUNERADA), "Tipo de licença inexistente.");
        require(_termino > _inicio, "A data de término deve ser posterior à data de início.");
        Licenca memory licenca = Licenca(TipoLicenca(_tipo), _inicio, _termino);
        licencas.push(licenca);
    }

    // RF08
    function adicionarAfastamento(string _motivo, uint _inicio, uint _termino, bool _integra) public {
        require(msg.sender == inss, "Acesso negado.");
        require(_termino > _inicio, "A data de término deve ser posterior à data de início.");
        Afastamento memory periodo = Afastamento(_motivo, _inicio, _termino, _integra);
        afastamentos.push(periodo);
    }

    // RF09
    function adicionarFerias(uint _inicio, uint _termino) public {
        require(msg.sender == empregador, "Acesso negado.");
        require(_termino > _inicio, "A data de término deve ser posterior à data de início.");
        Ferias memory periodoFerias = Ferias(_inicio, _termino);
        ferias.push(periodoFerias);
    }

    // RF10
    function tempoAposentadoria() public view returns (uint) {
        require(msg.sender == ctps || msg.sender == empregador || msg.sender == inss, "Acesso negado.");
        require(dataAdmissao != 0, "Este contrato ainda não foi firmado.");

        uint i;
        uint total = 0;

        // Tempo total do contrato
        if (dataRescisao != 0) {
            total = dataRescisao - dataAdmissao;
        } else {
            total = block.timestamp - dataAdmissao;
        }

        // Remoção dos períodos gozados por licenças que não são consideradas para
        // a integração da aposentadoria pelo INSS
        for (i = 0; i < licencas.length; i++) {
            if (licencas[i].tipo == TipoLicenca.NAO_REMUNERADA) {
                total = total - (licencas[i].termino - licencas[i].inicio);
            }
        }

        // Remoção dos períodos de afastamento que não integram na aposentadoria
        for (i = 0; i < afastamentos.length; i++) {
            if (!afastamentos[i].integra) {
                total = total - (afastamentos[i].termino - afastamentos[i].inicio);
            }
        }
        return total;
    }
}

// Carteira de Trabalho e Previdência Social
contract CTPS {

    address private empregado;
    address private inss;
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
        inss = msg.sender;
        empregado = _empregado;
        dadosPessoais = _dadosPessoais;
    }

    // RF02 e RF03 - a alteração de dados poderá ser feita somente pela Previdência Social
    function alterarDadosPessoais(address _dadosPessoais) public acesso(inss) {
        dadosPessoais = _dadosPessoais;
    }

    // RF04
    function solicitarContrato(string _info) public {
        Contrato c = new Contrato(this, _info, msg.sender, 0, inss);
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

    function tempoAposentadoria() public view returns (uint) {
        require(msg.sender == empregado || msg.sender == inss, "Acesso negado.");
        
        uint total = 0;

        for (uint i = 0; i < contratos.length; i++) {
            Contrato c = Contrato(contratos[i]);
            total = total + c.tempoAposentadoria();
        }

        return total;
    }

    // ---------
    // TESTES

    function obterDadosPessoais() public view acesso(inss) returns (address) {
        return dadosPessoais;
    }

    function obterSolicitacoes() public view acesso(empregado) returns (uint) {
        return solicitacoes.length;
    }

    function obterSolicitacao(uint _indice) public view acesso(empregado) returns (address) {
        require (_indice < solicitacoes.length, "Índice inválido.");
        return solicitacoes[_indice];
    }
    
    function obterContratos() public view acesso(empregado) returns (uint) {
        return contratos.length;
    }

    function obterContrato(uint _indice) public view acesso(empregado) returns (address) {
        require (_indice < contratos.length, "Índice inválido.");
        return contratos[_indice];
    }
}