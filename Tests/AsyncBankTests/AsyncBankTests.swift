import Foundation
import Testing
import Atomics

@testable import AsyncBank

actor InMemoryRepository: BankRepository {
    private var storage = [UUID: Int]()
    
    func store(_ account: AsyncBank.Account) {
        // simulate some async I/O
        usleep(UInt32.random(in: 1000...5000))
        storage[account.id] = account.balance
    }
    
    func getAccount(_ accountID: UUID) -> Account {
        // simulate some async I/O
        usleep(UInt32.random(in: 1000...5000))
        return Account(id: accountID, balance: storage[accountID] ?? 0)
    }
}

@Suite struct AsyncBankTests {
    let account1: Account
    let account2: Account
    let bank: Bank
    
    init() async {
        account1 = Account()
        account2 = Account()
        bank = await Bank(accounts: [account1, account2], repository: InMemoryRepository())
    }
    
    @Test func depositAndTransferScenario() async {
        let task1Complete = startTransfer1()
        let task2Complete = startTransfer2()
        
        waitForCompletion(task1Complete, task2Complete)
        
        let account1Balance = await bank.balanceFor(account1.id)
        let account2Balance = await bank.balanceFor(account2.id)
        
        #expect(account1Balance == 125)
        #expect(account2Balance == 175)
    }

    private func startTransfer1() -> ManagedAtomic<Bool> {
        let taskComplete = ManagedAtomic(false)
        
        Task {
            await bank.deposit(100, into: account1.id)
            await bank.transfer(25, from: account1.id, into: account2.id)
            taskComplete.store(true, ordering: .relaxed)
        }
        
        return taskComplete
    }

    private func startTransfer2() -> ManagedAtomic<Bool> {
        let taskComplete = ManagedAtomic(false)
        
        Task {
            await bank.deposit(200, into: account1.id)
            await bank.transfer(150, from: account1.id, into: account2.id)
            taskComplete.store(true, ordering: .relaxed)
        }
        
        return taskComplete
    }

    private func waitForCompletion(_ task1Complete: ManagedAtomic<Bool>, _ task2Complete: ManagedAtomic<Bool>) {
        while task1Complete.load(ordering: .relaxed) == false || task2Complete.load(ordering: .relaxed) == false {
            usleep(1000)
        }
    }
}


