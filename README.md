
# Phygital Assets 
A plataforma Phygital Assets é um ecossistema que integra ativos físicos ao mundo digital, permitindo a tokenização de bens tangíveis através de NFTs (Non-Fungible Tokens).



## DEPLOY 
forge script script/PhygitalAssetsDeploy.s.sol:PhygitalAssetsDeployScript --rpc-url $TESTRPC --broadcast -vvv

## MINT 
forge script script/PhygitalAssetsMint.s.sol:PhygitalAssetsMintScript --rpc-url $TESTRPC --broadcast -vvv


## LEMBRE-SE 

  #### Renomear o .env.example para .env e colocar as suas informações conta , provider (infura, alchemy), chaves.




## Foundry


## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```



