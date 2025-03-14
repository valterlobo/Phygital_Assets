// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./PhygitalAssetsStruct.sol";

/**
 * @title PhygitalAssets
 * @dev Contrato ERC1155 para gerenciamento de ativos físicos e digitais (phygital).
 * Permite a criação, mintagem e gerenciamento de ativos com supply limitado ou ilimitado.
 * O contrato é controlado pelo proprietário (Owner) e utiliza o padrão ERC1155 para tokens.
 */
contract PhygitalAssets is ERC1155, Ownable {
    // Nome do contrato de token
    string public name;

    // Símbolo do contrato de token
    string public symbol;

    // URI base para metadados do contrato
    string public uriAssets;

    // Mapeamento de tokenId para a estrutura do ativo (Asset)
    mapping(uint256 => Asset) private assets;

    // Eventos
    event AssetCreated(uint256 indexed tokenId, string name, uint256 maxSupply, bool supplyCapped);
    event AssetMinted(uint256 indexed tokenId, address indexed to, uint256 amount);
    event UriUpdated(uint256 indexed tokenId, string newUri);
    event AssetRemoved(uint256 indexed tokenId);
    event AssetMintedBatch(uint256[] tokenIds, address to, uint256[] amounts);

    // Erros personalizados
    error AssetAlreadyExists(uint256 tokenId);
    error AssetDoesNotExist(uint256 tokenId);
    error MaxSupplyExceeded(uint256 tokenId, uint256 maxSupply, uint256 requestedAmount);
    error InvalidOwner();
    error EmptyName();
    error EmptySymbol();
    error AmountOverflow();
    error InvalidAmount();
    error CannotRemoveAssetWithMintedTokens(uint256 tokenId);
    error InvalidURI();
    error InvalidAddress();
    error ArrayLengthMismatch();

    /**
     * @dev Modificador para verificar se um ativo existe.
     * @param id ID do token a ser verificado.
     */
    modifier activeAsset(uint256 id) {
        if (!_exists(id)) {
            revert AssetDoesNotExist(id);
        }
        _;
    }

    /**
     * @dev Construtor do contrato.
     * @param initialOwner Endereço do proprietário inicial do contrato.
     * @param nameAssets Nome do contrato de token.
     * @param symbolAssets Símbolo do contrato de token.
     * @param uriContract URI base para metadados do contrato.
     * @notice Reverte se o `initialOwner` for o endereço zero, ou se `nameAssets` ou `symbolAssets` forem vazios.
     */
    constructor(address initialOwner, string memory nameAssets, string memory symbolAssets, string memory uriContract)
        ERC1155("")
        Ownable(initialOwner)
    {
        if (initialOwner == address(0)) revert InvalidOwner();
        if (bytes(nameAssets).length == 0) revert EmptyName();
        if (bytes(symbolAssets).length == 0) revert EmptySymbol();
        name = nameAssets;
        symbol = symbolAssets;
        uriAssets = uriContract;
    }

    /**
     * @dev Cria um novo ativo.
     * @param tokenId ID único do token.
     * @param nm Nome do ativo.
     * @param ur URI do ativo.
     * @param maxSupply Supply máximo do ativo (ignorado se `supplyCapped` for false).
     * @param supplyCapped Indica se o supply do ativo é limitado.
     * @notice Reverte se o ativo já existir ou se o `tokenId` já estiver em uso.
     * @notice Apenas o proprietário pode chamar esta função.
     */
    function createAsset(uint256 tokenId, string calldata nm, string calldata ur, uint256 maxSupply, bool supplyCapped)
        external
        onlyOwner
    {
        if (_exists(tokenId)) {
            revert AssetAlreadyExists(tokenId);
        }

        if (bytes(ur).length == 0) {
            revert InvalidURI();
        }

        assets[tokenId] =
            Asset({id: tokenId, name: nm, totalSupply: 0, maxSupply: maxSupply, supplyCapped: supplyCapped, uri: ur});
        emit AssetCreated(tokenId, nm, maxSupply, supplyCapped);
    }

    /**
     * @dev Retorna os detalhes de um ativo.
     * @param tokenId ID do token.
     * @return Asset Estrutura do ativo correspondente ao `tokenId`.
     * @notice Reverte se o ativo não existir.
     */
    function getAsset(uint256 tokenId) external view returns (Asset memory) {
        return assets[tokenId];
    }

    /**
     * @dev Remove um ativo existente.
     * @param tokenId ID do token a ser removido.
     * @notice Reverte se o ativo não existir ou se houver tokens mintados (`totalSupply > 0`).
     * @notice Apenas o proprietário pode chamar esta função.
     */
    function removeAsset(uint256 tokenId) external onlyOwner activeAsset(tokenId) {
        // Verifica se há tokens mintados para o ativo
        if (assets[tokenId].totalSupply > 0) {
            revert CannotRemoveAssetWithMintedTokens(tokenId);
        }

        // Remove o ativo do mapeamento
        delete assets[tokenId];

        // Emite um evento para indicar que o ativo foi removido
        emit AssetRemoved(tokenId);
    }

    /**
     * @dev Minta tokens de um ativo para um endereço específico.
     * @param tokenId ID do token.
     * @param to Endereço que receberá os tokens.
     * @param amount Quantidade de tokens a serem mintados.
     * @notice Reverte se o ativo não existir, se o `amount` for zero, ou se o supply máximo for excedido.
     * @notice Apenas o proprietário pode chamar esta função.
     */
    function mintAsset(uint256 tokenId, address to, uint256 amount) external onlyOwner activeAsset(tokenId) {
        if (amount == 0) revert InvalidAmount();
        if (to == address(0)) revert InvalidAddress();

        if (assets[tokenId].supplyCapped) {
            if (assets[tokenId].totalSupply + amount > assets[tokenId].maxSupply) {
                revert MaxSupplyExceeded(tokenId, assets[tokenId].maxSupply, amount);
            }
        }

        _mint(to, tokenId, amount, "");

        assets[tokenId].totalSupply += amount;
        if (!assets[tokenId].supplyCapped) {
            assets[tokenId].maxSupply = assets[tokenId].totalSupply;
        }
        emit AssetMinted(tokenId, to, amount);
    }

    /**
     * @dev Minta tokens de múltiplos ativos para múltiplos endereços em uma única transação.
     * @param tokenIds IDs dos tokens.
     * @param to Endereços que receberão os tokens.
     * @param amounts Quantidades de tokens a serem mintados.
     * @notice Reverte se os arrays tiverem comprimentos diferentes, se algum ativo não existir, se algum endereço for inválido ou se o supply máximo for excedido.
     * @notice Apenas o proprietário pode chamar esta função.
     */
    function mintAssetBatch(uint256[] calldata tokenIds, address to, uint256[] calldata amounts) external onlyOwner {
        if (tokenIds.length != amounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!_exists(tokenIds[i])) {
                revert AssetDoesNotExist(tokenIds[i]);
            }
            if (to == address(0)) {
                revert InvalidAddress();
            }
            if (amounts[i] == 0) {
                revert InvalidAmount();
            }

            if (assets[tokenIds[i]].supplyCapped) {
                if (assets[tokenIds[i]].totalSupply + amounts[i] > assets[tokenIds[i]].maxSupply) {
                    revert MaxSupplyExceeded(tokenIds[i], assets[tokenIds[i]].maxSupply, amounts[i]);
                }
            }
        }

        _mintBatch(to, tokenIds, amounts, "");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            assets[tokenIds[i]].totalSupply += amounts[i];
            if (!assets[tokenIds[i]].supplyCapped) {
                assets[tokenIds[i]].maxSupply = assets[tokenIds[i]].totalSupply;
            }
        }
        emit AssetMintedBatch(tokenIds, to, amounts);
    }

    /**
     * @dev Retorna a URI de um ativo.
     * @param tokenId ID do token.
     * @return string URI do ativo.
     * @notice Reverte se o ativo não existir.
     */
    function uri(uint256 tokenId) public view override(ERC1155) activeAsset(tokenId) returns (string memory) {
        return assets[tokenId].uri;
    }

    /**
     * @dev Atualiza a URI de um ativo.
     * @param tokenId ID do token.
     * @param newUri Nova URI do ativo.
     * @return string URI atualizada.
     * @notice Reverte se o ativo não existir.
     * @notice Apenas o proprietário pode chamar esta função.
     */
    function setUri(uint256 tokenId, string calldata newUri)
        external
        onlyOwner
        activeAsset(tokenId)
        returns (string memory)
    {
        if (bytes(newUri).length == 0) {
            revert InvalidURI();
        }
        assets[tokenId].uri = newUri;
        emit UriUpdated(tokenId, newUri);
        return assets[tokenId].uri;
    }

    /**
     * @dev Retorna a URI do contrato.
     * @return string URI do contrato.
     */
    function contractURI() public view returns (string memory) {
        return uriAssets;
    }

    /**
     * @dev Verifica se o contrato suporta uma interface específica.
     * @param interfaceId ID da interface a ser verificada.
     * @return bool True se a interface for suportada, false caso contrário.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Verifica se um ativo existe.
     * @param id ID do token.
     * @return bool True se o ativo existir, false caso contrário.
     */
    function _exists(uint256 id) internal view virtual returns (bool) {
        return (bytes(assets[id].name).length > 0);
    }
}
