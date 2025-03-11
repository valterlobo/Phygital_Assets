Em Solidity, tanto `require` quanto `revert` com erros personalizados (`error`) são usados para validar condições e reverter transações quando essas condições não são atendidas. No entanto, eles têm diferenças importantes em termos de uso, custo de gas e legibilidade. Vamos explorar essas diferenças:

---

### 1. **`require`**
O `require` é uma função embutida em Solidity usada para validar condições. Se a condição for falsa, a execução é revertida e uma mensagem de erro opcional pode ser fornecida.

#### Sintaxe:
```solidity
require(condição, "Mensagem de erro");
```

#### Exemplo:
```solidity
function transfer(address to, uint256 amount) public {
    require(balance[msg.sender] >= amount, "Saldo insuficiente");
    balance[msg.sender] -= amount;
    balance[to] += amount;
}
```

#### Características:
- **Custo de gas**: Quando a condição falha, o `require` consome um pouco mais de gas do que o `revert` com erros personalizados, especialmente se uma mensagem de erro longa for fornecida.
- **Uso**: Ideal para validações simples e mensagens de erro descritivas.
- **Legibilidade**: Facilita a leitura do código, pois a mensagem de erro é fornecida diretamente.

---

### 2. **`error` (Erros Personalizados)**
A partir do Solidity 0.8.4, erros personalizados foram introduzidos. Eles permitem definir erros específicos que podem ser usados com o `revert` para reverter transações de forma mais eficiente em termos de gas.

#### Sintaxe:
```solidity
error NomeDoErro(arg1Type arg1, arg2Type arg2, ...);
```

#### Exemplo:
```solidity
error InsufficientBalance(uint256 available, uint256 required);

function transfer(address to, uint256 amount) public {
    if (balance[msg.sender] < amount) {
        revert InsufficientBalance(balance[msg.sender], amount);
    }
    balance[msg.sender] -= amount;
    balance[to] += amount;
}
```

#### Características:
- **Custo de gas**: Mais eficiente em termos de gas do que o `require`, especialmente quando a mensagem de erro é longa.
- **Uso**: Ideal para erros complexos ou quando você precisa passar dados adicionais sobre o erro.
- **Legibilidade**: Torna o código mais modular e organizado, especialmente em contratos grandes com muitos erros personalizados.

---

### Comparação Detalhada

| Característica               | `require`                          | `error` (Erros Personalizados)       |
|------------------------------|------------------------------------|--------------------------------------|
| **Custo de gas**             | Mais alto (especialmente com mensagens longas) | Mais baixo (mais eficiente)          |
| **Mensagens de erro**        | Mensagens de erro embutidas        | Dados estruturados e personalizados  |
| **Legibilidade**             | Boa para validações simples        | Melhor para erros complexos          |
| **Uso**                      | Validações simples e rápidas       | Erros personalizados e detalhados    |
| **Versão do Solidity**       | Disponível desde versões antigas   | Disponível a partir do Solidity 0.8.4|

---

### Quando Usar `require`?
- Para validações simples e diretas.
- Quando você precisa de uma mensagem de erro descritiva e não se preocupa com o custo de gas.
- Exemplo:
  ```solidity
  require(msg.sender == owner, "Somente o proprietário pode executar");
  ```

### Quando Usar `error`?
- Para erros complexos que exigem dados adicionais.
- Quando você deseja economizar gas, especialmente em contratos grandes ou com muitas validações.
- Para melhorar a organização e legibilidade do código.
- Exemplo:
  ```solidity
  error Unauthorized(address caller, address requiredOwner);

  function restrictedFunction() public {
      if (msg.sender != owner) {
          revert Unauthorized(msg.sender, owner);
      }
  }
  ```

### Exemplo Completo Comparando `require` e `error`

### Usando `require`:

```solidity
function transfer(address to, uint256 amount) public {
    require(balance[msg.sender] >= amount, "Saldo insuficiente");
    require(to != address(0), "Endereço de destino inválido");

    balance[msg.sender] -= amount;
    balance[to] += amount;
}
```

### Usando `error`:

```solidity

error InsufficientBalance(uint256 available, uint256 required);
error InvalidAddress(address provided);

function transfer(address to, uint256 amount) public {
    if (balance[msg.sender] < amount) {
        revert InsufficientBalance(balance[msg.sender], amount);
    }
    if (to == address(0)) {
        revert InvalidAddress(to);
    }

    balance[msg.sender] -= amount;
    balance[to] += amount;
}
```

## Error x Require:

- Use `require` para validações simples e quando a legibilidade direta é mais importante que a eficiência de gas.
- Use `error` para erros personalizados e complexos, especialmente em contratos grandes ou quando a economia de gas é crítica.


## Para trocar `require` por `error` em Solidity, você precisa seguir alguns passos. 

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
