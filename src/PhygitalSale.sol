// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./PhygitalAssets.sol";

contract PhygitalSale is Ownable, ReentrancyGuard {
    using Math for uint256;

    // Interface do contrato PhygitalAssets ERC-1155
    PhygitalAssets public immutable phygitalAssets;

    // Mapeamento de saques pendentes
    mapping(address => uint256) public pendingWithdrawals;

    // Endereço que receberá as taxas
    address public feeRecipient;
    // Percentual de taxa (em base 10000, onde 100 = 1%)
    uint256 public feePercentage;
    uint256 public constant MAX_FEE = 1000; // 10% máximo

    // Estrutura para cada venda
    struct Sale {
        address seller;
        address paymentReceiver;
        uint256[] tokenIds;
        uint256[] amounts;
        uint256 price;
        bool active;
        uint256 creationTime; //Adicionado tempo de criação
    }

    // Mapeamento de vendas
    mapping(uint256 => Sale) public sales;
    //uint256 public saleCounter;

    // Eventos
    event SaleCreated( //Adicionado tempo de criação
        uint256 indexed saleId,
        address seller,
        address paymentReceiver,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256 price,
        uint256 creationTime
    );
    event SaleCompleted(uint256 indexed saleId, address buyer, uint256 totalPrice, uint256 feeAmount);
    event FeeUpdated(uint256 newFeePercentage);
    event FeeRecipientUpdated(address newFeeRecipient);
    event SaleCancelled(uint256 indexed saleId);
    event FeesWithdrawn(address indexed feeRecipient, uint256 amount);

    // Erros personalizados
    error InvalidAddress(string message);
    error FeeExceedsMaximum();
    error ArraysLengthMismatch();
    error PriceMustBeGreaterThanZero();
    error SaleNotActive();
    error InsufficientPayment();
    error FeeTransferFailed();
    error PaymentTransferFailed();
    error RefundFailed();
    error NoFundsAvailable();
    error NotApprovedForTokens(); // Novo erro para aprovação de tokens
    error NotFeeRecipient(); // Novo erro para tentativa de saque de taxas por não feeRecipient

    constructor(
        address phygitalAssetsAddr,
        address feeRecipientAddr,
        uint256 initialFeePercentage,
        address initialOwner
    ) Ownable(initialOwner) {
        if (phygitalAssetsAddr == address(0)) revert InvalidAddress("PhygitalAssets address cannot be zero");
        if (feeRecipientAddr == address(0)) revert InvalidAddress("Fee recipient address cannot be zero");
        if (initialFeePercentage > MAX_FEE) revert FeeExceedsMaximum();
        if (isContract(feeRecipient)) revert InvalidAddress("Fee recipient cannot be a contract");

        phygitalAssets = PhygitalAssets(phygitalAssetsAddr);
        feeRecipient = feeRecipientAddr;
        feePercentage = initialFeePercentage;
    }

    // Criar uma nova venda
    function createSale(
        address paymentReceiverAddr,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 price,
        uint256 saleId
    ) external nonReentrant onlyOwner returns (uint256) {
        if (paymentReceiverAddr == address(0)) revert InvalidAddress("Payment Receiver cannot be zero");
        if (tokenIds.length != amounts.length) revert ArraysLengthMismatch();
        if (price == 0) revert PriceMustBeGreaterThanZero();

        uint256 creationTime = block.timestamp; //Adicionado tempo de criação

        sales[saleId] = Sale({
            seller: msg.sender,
            paymentReceiver: paymentReceiverAddr,
            tokenIds: tokenIds,
            amounts: amounts,
            price: price,
            active: true,
            creationTime: creationTime //Adicionado tempo de criação
        });

        emit SaleCreated(saleId, msg.sender, paymentReceiverAddr, tokenIds, amounts, price, creationTime); //Adicionado tempo de criação
        return saleId;
    }

    // Comprar um Phygital Asset
    function purchase(uint256 saleId) external payable nonReentrant {
        Sale storage sale = sales[saleId];
        if (!sale.active) revert SaleNotActive();
        if (msg.value < sale.price) revert InsufficientPayment();

        // Calcular taxa e valor líquido
        uint256 feeAmount = Math.mulDiv(sale.price, feePercentage, 10000);
        uint256 netAmount;
        bool success;
        (success, netAmount) = Math.trySub(sale.price, feeAmount);

        // Desativar a venda
        sale.active = false;

        // Acumular taxa no pendingWithdrawals em vez de transferir diretamente
        pendingWithdrawals[feeRecipient] += feeAmount;

        // Transferir valor líquido para o receiver definido
        Address.sendValue(payable(sale.paymentReceiver), netAmount);

        // Devolver troco se houver
        if (msg.value > sale.price) {
            Address.sendValue(payable(msg.sender), msg.value - sale.price);
        }

        // Realizar o mint dos assets
        phygitalAssets.mintAssetBatch(sale.tokenIds, msg.sender, sale.amounts);

        emit SaleCompleted(saleId, msg.sender, sale.price, feeAmount);
    }

    // Atualizar percentual de taxa (apenas owner)
    function setFeePercentage(uint256 newFeePercentage) external onlyOwner {
        if (newFeePercentage > MAX_FEE) revert FeeExceedsMaximum();
        feePercentage = newFeePercentage;
        emit FeeUpdated(newFeePercentage);
    }

    // Atualizar endereço do recebedor de taxas (apenas owner)
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        if (newFeeRecipient == address(0)) revert InvalidAddress("Fee Recipient cannot be zero");
        if (isContract(newFeeRecipient)) revert InvalidAddress("Fee Recipient cannot be a contract");
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(newFeeRecipient);
    }

    // Cancelar uma venda (apenas seller)
    function cancelSale(uint256 saleId) external onlyOwner {
        Sale storage sale = sales[saleId];
        if (!sale.active) revert SaleNotActive();
        sale.active = false;
        // Emitir o evento SaleCancelled
        emit SaleCancelled(saleId);
    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert NoFundsAvailable();
        pendingWithdrawals[msg.sender] = 0;
        Address.sendValue(payable(msg.sender), amount);
    }

    // Novo método para o feeRecipient retirar taxas acumuladas
    function withdrawFees() external nonReentrant onlyOwner {
        if (msg.sender != feeRecipient) revert NotFeeRecipient();

        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert NoFundsAvailable();

        pendingWithdrawals[msg.sender] = 0;
        Address.sendValue(payable(msg.sender), amount);

        emit FeesWithdrawn(msg.sender, amount);
    }

    function isContract(address addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }
}
