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
    init(delay: UInt32 = 0) {
        self.delay = delay
    }
    
    /// Stores an account in the repository.
    /// - Parameter account: The account to store.
    /// - Note: This method simulates some asynchronous I/O by sleeping for the specified delay.
    func store(_ account: AsyncBank.Account) {
        // simulate some async I/O
        usleep(delay)
        storage[account.id] = account.balance
    }
    
    /// Retrieves an account by its ID.
    /// - Parameter accountID: The UUID of the account to retrieve.
    /// - Returns: The account with the specified ID, or a new account with a balance of 0 if it does not exist.
    /// - Note: This method simulates some asynchronous I/O by sleeping for the specified delay.
    func getAccount(_ accountID: UUID) -> Account {
        // simulate some async I/O
        usleep(delay)
        return Account(id: accountID, balance: storage[accountID] ?? 0)
    }
}