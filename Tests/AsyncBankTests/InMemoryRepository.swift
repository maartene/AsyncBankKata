import Foundation
@testable import AsyncBank

/// An in-memory implementation of the `AccountRepository` protocol.
/// This repository simulates a database by storing accounts in memory.
/// It provides methods to store and retrieve accounts asynchronously.
actor InMemoryRepository: TransactionRepository {
    private var storage = [Transaction]()
    private let delay: UInt32
    
    /// Initializes the repository with an optional delay for simulating asynchronous I/O.
    /// - Parameter delay: The delay in microseconds to simulate I/O operations. Defaults to 0.
    /// - Note: The actual delay for the operations is `delay` +/- 10%.
    init(delay: UInt32 = 0) {
        self.delay = delay
    }

    func store(_ transaction: AsyncBank.Transaction) {
        usleep(approximately(delay))
        storage.append(transaction)
    }
    
    func retrieveTransactions() -> [AsyncBank.Transaction] {
        usleep(approximately(delay))
        return storage
    }
    
    private func approximately(_ value: UInt32) -> UInt32 {
        let range = (Double(value) * 0.9 ... Double(value) * 1.1)
        return UInt32(Double.random(in: range))
    }
}
