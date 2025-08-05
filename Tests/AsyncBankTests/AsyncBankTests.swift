import Foundation
import Testing
import Atomics

@testable import AsyncBank

@Suite("Bank should") struct AsyncBankTests {
    @Suite("for single transactions") struct SingleTransactions {
        let account = Account()
        @Test("deposit money into an account") func depositMoneyIntoAccount() async {
            let bank = await Bank(repository: InMemoryRepository())
            
            await bank.executeTransaction(.deposit(amount: 100, accountID: account.id))
            
            let finalBalance = await bank.balanceFor(account.id)
            #expect(finalBalance == 100)
        }

        @Test("withdraw money from an account") func withdrawMoneyFromAccount() async {
            let bank = await Bank(repository: InMemoryRepository())
            await bank.executeTransaction(.deposit(amount: 200, accountID: account.id))

            await bank.executeTransaction(.withdraw(amount: 50, accountID: account.id))
            
            let finalBalance = await bank.balanceFor(account.id)
            #expect(finalBalance == 150)
        }

        @Test("not allow withdrawing from an account with insufficient balance") func cannotWithdrawFromAccountWithInsufficientBalance() async {
            let bank = await Bank(repository: InMemoryRepository())
                
            await bank.executeTransaction(.withdraw(amount: 100, accountID: account.id))
            
            let finalBalance = await bank.balanceFor(account.id)
            #expect(finalBalance == 0)
        }
    }
    
    @Suite("when transferring from one account into another") struct TransferBetweenAccounts {
            let sourceAccount = Account()
            let destinationAccount = Account()

            @Test("decrease the balance of the source account and increase the balance of the target account") func transferAmount() async {
                let bank = await Bank(repository: InMemoryRepository())
                await bank.executeTransaction(.deposit(amount: 100, accountID: sourceAccount.id))

                await bank.executeTransaction(.transfer(amount: 70, from: sourceAccount.id, to: destinationAccount.id))
                
                let finalBalanceOfSourceAccount = await bank.balanceFor(sourceAccount.id)
                let finalBalanceOfDestinationAccount = await bank.balanceFor(destinationAccount.id)
                #expect(finalBalanceOfSourceAccount == 30)
                #expect(finalBalanceOfDestinationAccount == 70)
            }

            @Test("not decrease the balance of the source account and increase the balance of the target account when there is insufficient balance") func notTransferAmountInsufficientBalance() async {
                let bank = await Bank(repository: InMemoryRepository())
                await bank.executeTransaction(.deposit(amount: 100, accountID: sourceAccount.id))

                await bank.executeTransaction(.transfer(amount: 170, from: sourceAccount.id, to: destinationAccount.id))
                
                let finalBalanceOfSourceAccount = await bank.balanceFor(sourceAccount.id)
                let finalBalanceOfDestinationAccount = await bank.balanceFor(destinationAccount.id)
                #expect(finalBalanceOfSourceAccount == 100)
                #expect(finalBalanceOfDestinationAccount == 0)
            }
        }

    @Suite("for multiple simultaneous transactions") struct MultipleSimultaniousTransactions {
        let account1 = Account()
        let account2 = Account()
        
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
    }    
}


