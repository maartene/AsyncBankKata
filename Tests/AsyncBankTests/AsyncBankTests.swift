import Foundation
import Testing
import Atomics

@testable import AsyncBank

actor InMemoryRepository: AccountRepository {
    private var storage = [UUID: Int]()
    private let delay: UInt32
    
    init(delay: UInt32) {
        self.delay = delay
    }
    
    func store(_ account: AsyncBank.Account) {
        // simulate some async I/O
        usleep(delay)
        storage[account.id] = account.balance
    }
    
    func getAccount(_ accountID: UUID) -> Account {
        // simulate some async I/O
        usleep(delay)
        return Account(id: accountID, balance: storage[accountID] ?? 0)
    }
}

@Suite("Bank should") struct AsyncBankTests {
    let account1: Account
    let account2: Account
    
    init() async {
        account1 = Account()
        account2 = Account()
    }
    
    @Test("deposit and transfor money for two transactions correctly", arguments: [
        0,
        10,
        100,
        1000
    ]) func asyncDepositAndTransferScenario(delay: UInt32) async {
        let bank = await Bank(repository: InMemoryRepository(delay: delay))
        
        let task1Complete = startTransfer1(using: bank)
        usleep(10_000)
        let task2Complete = startTransfer2(using: bank)
        
        waitForCompletion(task1Complete, task2Complete)
        
        let account1Balance = await bank.balanceFor(account1.id)
        let account2Balance = await bank.balanceFor(account2.id)
        
        #expect(account1Balance == 125)
        #expect(account2Balance == 175)
    }
    
    // MARK: test helpers
    private func startTransfer1(using bank: Bank) -> ManagedAtomic<Bool> {
        startTransfer(using: bank, transactions: [
            .deposit(amount: 100, accountID: account1.id),
            .transfer(amount: 25, from: account1.id, to: account2.id)
        ])
    }

    private func startTransfer2(using bank: Bank) -> ManagedAtomic<Bool> {
        startTransfer(using: bank, transactions: [
            .deposit(amount: 200, accountID: account1.id),
            .transfer(amount: 150, from: account1.id, to: account2.id)
            ])
    }

    private func startTransfer(using bank: Bank, transactions: [Transaction]) -> ManagedAtomic<Bool> {
        let taskComplete = ManagedAtomic(false)
        
        Task {
            for transactions in transactions {
                switch transactions {
                case .deposit(let amount, let accountID):
                    await bank.deposit(amount, into: accountID)
                case .transfer(let amount, let from, let to):
                    await bank.transfer(amount, from: from, into: to)
                case .withdraw(let amount, let accountID):
                    await bank.withdraw(amount, from: accountID)
                }
            }
            taskComplete.store(true, ordering: .relaxed)
        }
        
        return taskComplete
    }

    private func waitForCompletion(_ tasks: ManagedAtomic<Bool>...) {
        while tasks.contains(where: { $0.load(ordering: .relaxed) == false }) {
            usleep(1000)
        }
    }
}


