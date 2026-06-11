import Foundation

/// The Bank actor manages accounts and transactions.
/// Interaction with the bank is asynchronous and thread-safe.
/// Inject an `AccountRepository` to handle account storage and retrieval.
actor Bank {
    private let repository: AccountRepository
    
    /// Initializes the Bank with a given repository.
    init(repository: AccountRepository) async {
        self.repository = repository
    }

    /// Retrieves the balance for a specific account.
    /// - Parameter accountID: The UUID of the account to check.
    /// - Returns: The balance of the account, or 0 if the account does not exist
    func balanceFor(_ accountID: UUID) async -> Int {
        await repository.getAccount(accountID).balance
    }

    /// Executes a transaction on the bank.
    /// - Parameter transaction: The transaction to execute, which can be a deposit, transfer, or withdrawal.
    /// - Note: This method will return when the transaction is complete.
    func executeTransaction(_ transaction: Transaction) async {
        do {
            switch transaction {
            case .deposit(let amount, let accountID):
                try await repository.performAtomicOperation([
                    AccountBalanceOperation(accountID: accountID, delta: .increase(amount: amount))
                ])
            case .transfer(let amount, let from, let to):
                try await repository.performAtomicOperation([
                    AccountBalanceOperation(accountID: to, delta: .increase(amount: amount)),
                    AccountBalanceOperation(accountID: from, delta: .decrease(amount: amount)),
                    
                ])
            case .withdraw(let amount, let accountID):
                try await repository.performAtomicOperation([
                    AccountBalanceOperation(accountID: accountID, delta: .decrease(amount: amount))
                ])
            }
        } catch {
            print("Failed to perform transaction: \(transaction) due to error: \(error)")
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

/// Protocol for an account repository that handles asynchronous storage and retrieval of accounts.
/// Think of this as representing a database or any persistent storage mechanism.
protocol AccountRepository: Actor {
    /// Retrieves an account by its ID.
    /// - Parameter accountID: The UUID of the account to retrieve.
    /// - Returns: The account with the specified ID, or a new account with a balance of 0 if it does not exist.
    func getAccount(_ accountID: UUID) -> Account
    
    func performAtomicOperation(_ operations: [AccountBalanceOperation]) throws
}

struct AccountBalanceOperation {
    enum BalanceOperation {
        case increase(amount: Int), decrease(amount: Int)
    }
    let accountID: UUID
    let delta: BalanceOperation
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
    mutating func withdraw(_ amount: Int) throws {
        guard amount <= balance else {
            throw AccountError.insufficientBalance
        }
        
        balance -= amount
    }
}

enum AccountError: Error {
    case insufficientBalance
}
