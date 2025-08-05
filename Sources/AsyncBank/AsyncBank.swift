import Foundation

protocol AccountRepository: Actor {
    func store(_ account: Account)
    func getAccount(_ accountID: UUID) -> Account
}

actor Bank {
    private let repository: AccountRepository
    
    init(repository: AccountRepository) async {
        self.repository = repository
    }

    func balanceFor(_ accountID: UUID) async -> Int {
        await repository.getAccount(accountID).balance
    }

    func executeTransaction(_ transaction: Transaction) async {
        switch transaction {
        case .deposit(let amount, let accountID):
            await deposit(amount, into: accountID)
        case .transfer(let amount, let from, let to):
            await transfer(amount, from: from, into: to)
        case .withdraw(let amount, let accountID):
            await withdraw(amount, from: accountID)
        }
    }
    
    private func deposit(_ amount: Int, into accountID: UUID) async  {
        var account = await repository.getAccount(accountID)
        
        account.deposit(amount)
        
        await repository.store(account)
    }
    
    private func withdraw(_ amount: Int, from accountID: UUID) async  {
        var account = await repository.getAccount(accountID)
        
        account.withdraw(amount)
        
        await repository.store(account)
    }
    
    private func transfer(_ amount: Int, from sourceAccountID: UUID, into destinationAccountID: UUID) async  {
        guard await balanceFor(sourceAccountID) >= amount else {
            return
        }
        
        await deposit(amount, into: destinationAccountID)
        await withdraw(amount, from: sourceAccountID)
    }
}

struct Account {
    let id: UUID
    private(set) var balance = 0
    
    init(id: UUID = UUID(), balance: Int = 0) {
        self.id = id
        self.balance = balance
    }
    
    mutating func deposit(_ amount: Int) {
        balance += amount
    }
    
    mutating func withdraw(_ amount: Int) {
        balance -= amount
    }
}

enum Transaction {
    case deposit(amount: Int, accountID: UUID)
    case transfer(amount: Int, from: UUID, to: UUID)
    case withdraw(amount: Int, accountID: UUID)
}