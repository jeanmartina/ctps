pragma solidity ^0.4.24;

/// @title CTPS
/// @author Makhles R. Lange

// Carteira de Trabalho e Previdência Social
contract CTPS {

    // Documento de Identificação Original
    enum DIO {
        RG,
        CNH,         // Carteira Nacional de Habilitação posterior à Lei nº 9.503/97
        PASSAPORTE,
        CR           // Certificado de Reservista
    }

    enum EstadoCivil { SOLTEIRO, CASADO, DIVORCIADO, SEPARADO, VIUVO }

    struct TituloEleitoral {
        uint40 numero;  // 12 dígitos
        uint16 secao;
        uint16 zona;    // SP possui 426 zonas eleitorais
    }
    
    // Dados do empregado
    struct DadosPessoais {
        string nome;
        string nomeMae;
        string nomePai;
        uint cpf;
        EstadoCivil estadoCivil;
        TituloEleitoral tituloEleitoral;
    }
    DadosPessoais private dadosPessoais;
    address private empregado;
    uint private dataEmissao;

    constructor(string _nome, string _nomeMae, string _nomePai, uint _cpf, uint _estadoCivil,
             uint40 _tituloNumero, uint16 _tituloSecao, uint16 _tituloZona) public {
        
        require(
            _estadoCivil < 5,
            "Estado civil inexistente. Informar um valor inferior a 5."
        );
        empregado = msg.sender;
        dataEmissao = now;
        dadosPessoais.nome = _nome;
        dadosPessoais.nomeMae = _nomeMae;
        dadosPessoais.nomePai = _nomePai;
        dadosPessoais.cpf = _cpf;
        dadosPessoais.estadoCivil = EstadoCivil(_estadoCivil);
        dadosPessoais.tituloEleitoral.numero = _tituloNumero;
        dadosPessoais.tituloEleitoral.secao = _tituloSecao;
        dadosPessoais.tituloEleitoral.zona = _tituloZona;
    }

}