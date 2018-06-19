# Carteira de Trabalho e Previdência Social

Implementação de um contrato inteligente escrito na linguagem Solidity que representa uma Carteira de Trabalho.


## Hash dos Dados Pessoais

O arquivo [dados_pessoais](./dados_pessoais) contém alguns dados fictícios utilizados como exemplo na geração da carteira de trabalho. A geração dos dados foi feita através do site [4devs](https://www.4devs.com.br/).

Para se calcular o hash desses dados, deve-se utilizar uma função de dispersão criptográfica, tal como o [SHA-1](https://en.wikipedia.org/wiki/SHA-1 "Wikipedia: SHA-1"). Pode-se utilizar o programa `sha1sum`, disponível na maioria dos sistemas Unix. Fornecendo-se o arquivo com os dados pessoais, este programa produz um resumo de mensagem de 160 bits (20 bytes), na forma de um número hexadecimal de 40 dígitos:

```
% sha1sum dados_pessoais
0c6c57e6e93725646e60bb23308a054e8870aa9c  dados_pessoais
```

Este número é utilizado como entrada no Remix, uma IDE que possui um simulador de contratos do Ethereum.