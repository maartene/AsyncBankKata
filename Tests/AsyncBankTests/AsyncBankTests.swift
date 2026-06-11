import Foundation
import Testing

@testable import AsyncBank

@Suite struct AsyncBankTests {
    @Suite struct `Scenario: single bank transactions` {
        let account = Account()
        @Test func `Example: deposit money into an account`() async {
            let bank = await Bank(repository: InMemoryRepository())

            await bank.executeTransaction(.deposit(amount: 100, accountID: account.id))

            #expect(await bank.balanceFor(account.id) == 100)
        }

        @Test func `Example: withdraw money from an account`() async {
            let bank = await Bank(repository: InMemoryRepository())
            await bank.executeTransaction(.deposit(amount: 200, accountID: account.id))

            await bank.executeTransaction(.withdraw(amount: 50, accountID: account.id))

            #expect(await bank.balanceFor(account.id) == 150)
        }

        @Test func `Example: cannot withdraw money from an account with insufficient balance`() async {
            let bank = await Bank(repository: InMemoryRepository())

            await bank.executeTransaction(.withdraw(amount: 100, accountID: account.id))

            #expect(await bank.balanceFor(account.id) == 0)
        }
    }

    @Suite struct `Scenario: transferring from one account into another` {
        let sourceAccount = Account()
        let destinationAccount = Account()

        @Test func `Example: decrease the balance of the source account and increase the balance of the target account`() async {
            let bank = await Bank(repository: InMemoryRepository())
            await bank.executeTransaction(.deposit(amount: 100, accountID: sourceAccount.id))

            await bank.executeTransaction(
                .transfer(amount: 70, from: sourceAccount.id, to: destinationAccount.id))

            #expect(await bank.balanceFor(sourceAccount.id) == 30)
            #expect(await bank.balanceFor(destinationAccount.id) == 70)
        }

        @Test func `not change account balances when there is insufficient balance`() async {
            let bank = await Bank(repository: InMemoryRepository())
            await bank.executeTransaction(.deposit(amount: 100, accountID: sourceAccount.id))

            await bank.executeTransaction(
                .transfer(amount: 170, from: sourceAccount.id, to: destinationAccount.id))

            #expect(await bank.balanceFor(sourceAccount.id) == 100)
            #expect(await bank.balanceFor(destinationAccount.id) == 0)
        }
    }

    @Suite struct `Scenario: multiple sequential transactions` {
        let account1 = Account()
        let account2 = Account()
        
        let transactions: [Transaction]
        
        init() {
            transactions = [
                .deposit(amount: 100, accountID: account1.id),
                .transfer(amount: 25, from: account1.id, to: account2.id),
                .deposit(amount: 200, accountID: account1.id),
                .transfer(amount: 150, from: account1.id, to: account2.id),
            ]
        }
        
        @Test(arguments: [
            0,
            10,
            100,
            1000,
        ]) func `Example: two sequential transactions`(delay: UInt32) async {
            let bank = await Bank(repository: InMemoryRepository(delay: delay))
            
            for transaction in transactions {
                await bank.executeTransaction(transaction)
            }

            #expect(await bank.balanceFor(account1.id) == 125)
            #expect(await bank.balanceFor(account2.id) == 175)
        }
    }
    
    @Suite struct `Scenario: perform multiple simultanious transactions` {
        let account1 = Account()
        let account2 = Account()
        let account3 = Account()

        @Test(arguments: [
                0,
                10,
                100,
                1000,
        ]) func `Example: deposit and transfor money for two transactions correctly`(delay: UInt32) async {
            let bank = await Bank(repository: InMemoryRepository(delay: delay))

            async let t1 = startTransfer1(using: bank)
            usleep(10_000)
            async let t2 = startTransfer2(using: bank)
            await t1.value
            await t2.value

            #expect(await bank.balanceFor(account1.id) == 125)
            #expect(await bank.balanceFor(account2.id) == 175)
        }

        @Test(arguments: [
            0,
            10,
            100,
            1000,
        ]) func `Example: triangle transfer`(delay: UInt32) async {
            let bank = await Bank(repository: InMemoryRepository(delay: delay))

            async let t3 = startTransfer3(using: bank)
            usleep(10_000)
            async let t4 = startTransfer4(using: bank)
            usleep(10_000)
            async let t5 = startTransfer5(using: bank)
            await t3.value
            await t4.value
            await t5.value

            #expect(await bank.balanceFor(account1.id) == 100)
            #expect(await bank.balanceFor(account2.id) == 100)
            #expect(await bank.balanceFor(account3.id) == 100)
        }
        
        private func startTransfer(using bank: Bank, transactions: [Transaction]) -> Task<Void, Never> {
            Task {
                for transaction in transactions {
                    await bank.executeTransaction(transaction)
                }
            }
        }

        private func startTransfer1(using bank: Bank) -> Task<Void, Never> {
            startTransfer(
                using: bank,
                transactions: [
                    .deposit(amount: 100, accountID: account1.id),
                    .transfer(amount: 25, from: account1.id, to: account2.id),
                ])
        }

        private func startTransfer2(using bank: Bank) -> Task<Void, Never> {
            startTransfer(
                using: bank,
                transactions: [
                    .deposit(amount: 200, accountID: account1.id),
                    .transfer(amount: 150, from: account1.id, to: account2.id),
                ])
        }

        private func startTransfer3(using bank: Bank) -> Task<Void, Never> {
            startTransfer(
                using: bank,
                transactions: [
                    .deposit(amount: 100, accountID: account1.id),
                    .transfer(amount: 50, from: account1.id, to: account2.id),
                ])
        }

        private func startTransfer4(using bank: Bank) -> Task<Void, Never> {
            startTransfer(
                using: bank,
                transactions: [
                    .deposit(amount: 100, accountID: account2.id),
                    .transfer(amount: 50, from: account2.id, to: account3.id),
                ])
        }

        private func startTransfer5(using bank: Bank) -> Task<Void, Never> {
            startTransfer(
                using: bank,
                transactions: [
                    .deposit(amount: 100, accountID: account3.id),
                    .transfer(amount: 50, from: account3.id, to: account1.id),
                ])
        }
    }
}
