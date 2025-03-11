### Error x Require:
Para trocar `require` por `error` em Solidity, você precisa seguir alguns passos. 

A partir da versão 0.8.4 do Solidity, é possível definir erros personalizados usando a palavra - chave`error`,
    o que torna o código mais eficiente em termos de gás e mais legível.Vou te mostrar como fazer isso no seu contrato.

### Passos para substituir `require` por `error`:

1. ** Defina os erros personalizados ** no início do contrato, após os imports e antes das variáveis de estado.
2. ** Substitua os`require` ** por`revert` com o erro correspondente.
3. ** Remova as mensagens de erro em string ** (elas agora serão representadas pelos nomes dos erros personalizados).

Aqui está o seu contrato revisado com `require` substituído por `error`:


### Mudanças realizadas:
1. ** Erros personalizados definidos:**
    - `AssetAlreadyExists`: Para quando um asset com o mesmo `tokenId` já existe.
   - `AssetDoesNotExist`: Para quando um asset não existe.
   - `MaxSupplyExceeded`: Para quando o limite máximo de supply é excedido, com parâmetros adicionais para debugging.

2. ** Substituição de `require`:**
    - Cada`require` foi substituído por um `if` com `revert` e o erro correspondente.
   - Por exemplo:
```solidity
     require(!_exists(tokenId), "This Asset ( EXIST [ID]");
     ```
virou:
```solidity
     if (_exists(tokenId)) {
         revert AssetAlreadyExists(tokenId);
     }
     ```

3. ** Parâmetros nos erros:**
    - Nos casos em que faz sentido, adicionei parâmetros ao erro(como`tokenId`, `maxSupply`, e`requestedAmount`) para fornecer mais contexto ao depurar falhas.

### Benefícios:
- ** Eficiência de gás:** Usar`error` ao invés de `require` com strings reduz o custo de gás, já que as mensagens de erro não são armazenadas na blockchain.
- ** Clareza:** Erros personalizados tornam o código mais legível e informam exatamente o que deu errado.
- ** Debugging:** Os parâmetros nos erros ajudam a identificar o problema rapidamente.
