# Carteira de Trabalho e Previdência Social

Implementação de um contrato inteligente escrito na linguagem Solidity que representa uma Carteira de Trabalho. Testes de execução foram feitos na IDE Remix.

## Configuração da IDE Remix
Selecionar o compilador `0.4.24+commit.e67f0147` na aba _Settings_.


## `RF01` - Criação da Carteira de Trabalho

A criação da Carteira de Trabalho pode feita em alguma das instalações da Previdência Social. Supõe-se a existência de uma aplicação que possua um formulário para inserção dos dados da pessoa e que seja capaz de se comunicar com a plataforma Ethereum. Esta aplicação pode chamar o construtor do contrato CTPS passando-se o endereço da conta da pessoa no Ethereum e o _hash_ dos seus dados pessoais (vide Seção __Hash dos Dados Pessoais__):
```
    constructor(address _empregado, uint8 _dummy, address _dadosPessoais) public {
        previdenciaSocial = msg.sender;
        empregado = _empregado;
        dadosPessoais = _dadosPessoais;
    }
```

Obs.: o parâmetro `dummy` é necessário devido a um _bug_ que encontrei que não permite a instanciação de um contrato passando dois parâmetros do tipo `address` em sequência. Não se sabe se o _bug_ está presente somente no Remix ou se é alguma restrição da linguagem.


## `RF02` e `RF03` - Alteração dos dados pessoais

Percebe-se que o endereço da Previdência Social é armazenada na carteira de trabalho em seu construtor. Isto é necessário para permitir a alteração dos dados pessoais do dono da CTPS. 
Assim como é feito em uma CTPS física, a alteração dos dados pessoais deverá ser feita pela Previdência Social. Para tal, foi definido o método `alterarDadosPessoais`:
```
    function alterarDadosPessoais(address _dadosPessoais) public onlyBy(previdenciaSocial) {
        dadosPessoais = _dadosPessoais;
    }
``` 

### Hash dos Dados Pessoais

O arquivo [dados_pessoais](./dados_pessoais) contém alguns dados fictícios utilizados como exemplo na geração da carteira de trabalho. A geração dos dados foi feita através do site [4devs](https://www.4devs.com.br/).

Para se calcular o hash desses dados, deve-se utilizar uma função de dispersão criptográfica, tal como o [SHA-1](https://en.wikipedia.org/wiki/SHA-1 "Wikipedia: SHA-1"). Pode-se utilizar o programa `sha1sum`, disponível na maioria dos sistemas Unix. Fornecendo-se o arquivo com os dados pessoais, este programa produz um resumo de mensagem de 160 bits (20 bytes), na forma de um número hexadecimal de 40 dígitos:
```
% sha1sum dados_pessoais
0c6c57e6e93725646e60bb23308a054e8870aa9c  dados_pessoais
```
Após adicionar o prefixo `0x`, este número pode ser usado no construtor da CTPS e como parâmetro da função `alterarDadosPessoais`.


## `RF04` - Solicitação de Firma de Contrato

Um empregador pode fazer uma solicitação de firma de contrato com uma pessoa ao chamar o método `solicitarFirmaContrato`. O endereço do contrato de trabalho deve ser passado como parâmetro:
```
    function solicitarFirmaContrato(address _contrato) public {
        uint8 indice = solicitacoes.push(_contrato) - 1;
        emit SolicitacaoContrato(_contrato, indice);
    }
```
A solicitação é armazenada no arranjo dinâmico `solicitacoes`. Um evento com o endereço do contrato e seu índice no arranjo é emitido para que o dono da carteira possa aceitar ou rejeitar a solicitação. Utilizou-se o tipo `uint8` para o índice da solicitação por ser o menor tipo inteiro disponível e por se supor que uma pessoa não terá mais de 256 solicitações de contrato em um dado momento.


## `RF05` - Aceite & Rejeição de Firma de Contrato

Ao receber o evento de solicitação de firma de contrato em sua interface, o dono da CTPS poderá aceitar firmar o contrato através do método `aceitarSolicitacao`. O índice da solicitação deverá ser passado como parâmetro. O contrato é adicionado no arranjo de contratos do trabalhador, `contratos`, e removido do arranjo de solicitações:
```
    function aceitarSolicitacao(uint8 _indice) public onlyBy(empregado) {
        contratos.push(solicitacoes[indice]);
        delete solicitacoes[indice];
    }
```
Semelhantemente, o dono da carteira de trabalho pode decidir-se por não aceitar a proposta de trabalho, e a solicitação será removida do arranjo de solicitações:
```
    function rejeitarSolicitacao(uint8 _indice) public onlyBy(empregado) {
        delete solicitacoes[indice];
    }
```


