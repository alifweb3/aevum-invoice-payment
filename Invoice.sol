// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract InvoicePayment {
    IERC20 public immutable tusd8;
    uint256 public nextInvoiceId;

    struct Invoice {
        address merchant;
        address payee;
        uint256 amount;
        string description;
        bool paid;
        uint256 createdAt;
    }

    mapping(uint256 => Invoice) public invoices;

    event InvoiceCreated(uint256 indexed id, address indexed merchant, address payee, uint256 amount, string description);
    event InvoicePaid(uint256 indexed id, address indexed payer, uint256 amount);

    constructor(address _tusd8) {
        tusd8 = IERC20(_tusd8);
    }

    function createInvoice(address payee, uint256 amount, string calldata description) external returns (uint256) {
        uint256 id = nextInvoiceId++;
        invoices[id] = Invoice({
            merchant: msg.sender,
            payee: payee,
            amount: amount,
            description: description,
            paid: false,
            createdAt: block.timestamp
        });
        emit InvoiceCreated(id, msg.sender, payee, amount, description);
        return id;
    }

    function payInvoice(uint256 id) external {
        Invoice storage inv = invoices[id];
        require(!inv.paid, "Already paid");
        require(inv.amount > 0, "Invalid invoice");

        require(tusd8.transferFrom(msg.sender, inv.payee, inv.amount), "Transfer failed");
        inv.paid = true;

        emit InvoicePaid(id, msg.sender, inv.amount);
    }
}