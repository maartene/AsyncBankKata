import Atomics
import Foundation
@testable import AsyncBank

func startTransfer(using bank: Bank, transactions: [Transaction]) -> ManagedAtomic<Bool> {
    let taskComplete = ManagedAtomic(false)
    
    Task {
        for transactions in transactions {
            await bank.executeTransaction(transactions)
        }
        taskComplete.store(true, ordering: .relaxed)
    }
    
    return taskComplete
}

func waitForCompletion(_ tasks: ManagedAtomic<Bool>...) {
    while tasks.contains(where: { $0.load(ordering: .relaxed) == false }) {
        usleep(1000)
    }
}

typealias SafeBool = ManagedAtomic<Bool>