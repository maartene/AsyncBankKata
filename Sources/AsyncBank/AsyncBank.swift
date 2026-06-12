import Foundation

/// The Bank actor manages accounts and transactions.
/// Interaction with the bank is asynchronous and thread-safe.
/// Inject an `AccountRepository` to handle account storage and retrieval.
actor Bank {
    private let repository: TransactionRepository
    
    /// Initializes the Bank with a given repository.
    init(repository: TransactionRepository) async {
        self.repository = repository
    }
    
    /// Retrieves the balance for a specific account.
    /// - Parameter accountID: The UUID of the account to check.
    /// - Returns: The balance of the account, or 0 if the account does not exist
    func balanceFor(_ accountID: UUID) async -> Int {
        let transactions = await repository.retrieveTransactions()
        var accounts = AccountStorage()
        
        for transaction in transactions {
            switch transaction {
            case .deposit(let amount, let accountID):
                executeDeposit(accountID: accountID, amount: amount, accounts: &accounts)
            case .withdraw(let amount, let accountID):
                executeWithdrawal(accountID: accountID, amount: amount, accounts: &accounts)
            case .transfer(let amount, let sourceAccountID, let destinationAccountID):
                executeTransfer(amount: amount, sourceAccountID: sourceAccountID, destinationAccountID: destinationAccountID, accounts: &accounts)
            }
        }
        
        return accounts.getBalance(for: accountID)
    }

    /// Executes a transaction on the bank.
    /// - Parameter transaction: The transaction to execute, which can be a deposit, transfer, or withdrawal.
    /// - Note: This method will return when the transaction is complete.
    func executeTransaction(_ transaction: Transaction) async {
        await repository.store(transaction)
    }
    
    private func executeDeposit(accountID: UUID, amount: Int, accounts: inout AccountStorage) {
        accounts.addBalance(to: accountID, amount: amount)
    }
    
    private func executeWithdrawal(accountID: UUID, amount: Int, accounts: inout AccountStorage) {
        if accounts.getBalance(for: accountID) >= amount {
            accounts.addBalance(to: accountID, amount: -amount)
        }
    }
    
    private func executeTransfer(amount: Int, sourceAccountID: UUID, destinationAccountID: UUID, accounts: inout AccountStorage) {
        if accounts.getBalance(for: sourceAccountID) >= amount {
            accounts.addBalance(to: sourceAccountID, amount: -amount)
            accounts.addBalance(to: destinationAccountID, amount: amount)
        }
    }
    
    struct AccountStorage {
        private var storage = [Account]()
        
        mutating func addBalance(to accountID: UUID, amount: Int) {
            if let index = storage.firstIndex(where: { $0.id == accountID }) {
                storage[index] = Account(id: accountID, balance: storage[index].balance + amount)
            } else {
                storage.append(Account(id: accountID, balance: amount))
            }
        }
        
        func getBalance(for accountID: UUID) -> Int {
            storage.first {
                $0.id == accountID
            }?.balance ?? 0
        }
    }
    
}

/// Represents a transaction that can be executed on the bank.
/// Transactions can be deposits, transfers, or withdrawals.
/// - `deposit`: Deposit a specified amount into an account.
/// - `transfer`: Transfer a specified amount from one account to another.
/// - `withdraw`: Withdraw a specified amount from an account.
enum Transaction {
    case deposit(amount: Int, accountID: UUID)
    case transfer(amount: Int, from: UUID, to: UUID)
    case withdraw(amount: Int, accountID: UUID)
}

protocol TransactionRepository: Actor {
    func store(_ transaction: Transaction)
    func retrieveTransactions() -> [Transaction]
}

/// Represents a bank account with a unique identifier and a balance.
/// - `id`: A unique identifier for the account.
/// - `balance`: The current balance of the account, initialized to 0.
struct Account {
    let id: UUID
    private(set) var balance = 0
    
    /// Initializes a new account with a unique identifier and an optional initial balance.
    /// - Parameters:
    ///   - id: The unique identifier for the account. Defaults to a new UUID.
    ///   - balance: The initial balance for the account. Defaults to 0.
    init(id: UUID = UUID(), balance: Int = 0) {
        self.id = id
        self.balance = balance
    }
    
    /// Deposits an amount into the account.
    /// - Parameter amount: The amount to deposit into the account.
    mutating func deposit(_ amount: Int) {
        balance += amount
    }
    
    /// Withdraws an amount from the account.
    /// - Parameter amount: The amount to withdraw from the account.
    /// - Note: This method does not check if the account has sufficient balance.
    mutating func withdraw(_ amount: Int) {
        balance -= amount
    }
}

