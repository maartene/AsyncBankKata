import Foundation
@testable import AsyncBank

/// An in-memory implementation of the `AccountRepository` protocol.
/// This repository simulates a database by storing accounts in memory.
/// It provides methods to store and retrieve accounts asynchronously.
actor InMemoryRepository: AccountRepository {
    private var storage = [UUID: Int]()
    private let delay: UInt32
    
    /// Initializes the repository with an optional delay for simulating asynchronous I/O.
    /// - Parameter delay: The delay in microseconds to simulate I/O operations. Defaults to 0.
    /// - Note: The actual delay for the operations is `delay` +/- 10%.
    init(delay: UInt32 = 0) {
        self.delay = delay
    }
    
    /// Retrieves an account by its ID.
    /// - Parameter accountID: The UUID of the account to retrieve.
    /// - Returns: The account with the specified ID, or a new account with a balance of 0 if it does not exist.
    /// - Note: This method simulates some asynchronous I/O by sleeping for approximately the specified delay (+/- 10%).
    func getAccount(_ accountID: UUID) -> Account {
        // simulate some async I/O
        usleep(approximately(delay))
        return Account(id: accountID, balance: storage[accountID] ?? 0)
    }

    private func approximately(_ value: UInt32) -> UInt32 {
        let range = (Double(value) * 0.9 ... Double(value) * 1.1)
        return UInt32(Double.random(in: range))
    }
    
    func performAtomicOperation(_ operations: [AccountBalanceOperation]) throws {
        var updatedAccounts = storage
        
        for operation in operations {
                var account = Account(id: operation.accountID, balance: storage[operation.accountID] ?? 0)
                switch operation.delta {
                case .increase(let amount):
                    account.deposit(amount)
                case .decrease(let amount):
                    try account.withdraw(amount)
                }
                
                updatedAccounts[operation.accountID] = account.balance
        }
            
        storage = updatedAccounts
    }
}
