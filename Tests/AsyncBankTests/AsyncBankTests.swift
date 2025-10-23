import Foundation
import Testing

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

        @Test("not allow withdrawing from an account with insufficient balance")
        func cannotWithdrawFromAccountWithInsufficientBalance() async {
            let bank = await Bank(repository: InMemoryRepository())

            await bank.executeTransaction(.withdraw(amount: 100, accountID: account.id))

            let finalBalance = await bank.balanceFor(account.id)
            #expect(finalBalance == 0)
        }
    }

    @Suite("when transferring from one account into another") struct TransferBetweenAccounts {
        let sourceAccount = Account()
        let destinationAccount = Account()

        @Test(
            "decrease the balance of the source account and increase the balance of the target account"
        ) func transferAmount() async {
            let bank = await Bank(repository: InMemoryRepository())
            await bank.executeTransaction(.deposit(amount: 100, accountID: sourceAccount.id))

            await bank.executeTransaction(
                .transfer(amount: 70, from: sourceAccount.id, to: destinationAccount.id))

            let finalBalanceOfSourceAccount = await bank.balanceFor(sourceAccount.id)
            let finalBalanceOfDestinationAccount = await bank.balanceFor(destinationAccount.id)
            #expect(finalBalanceOfSourceAccount == 30)
            #expect(finalBalanceOfDestinationAccount == 70)
        }

        @Test(
            "not decrease the balance of the source account and increase the balance of the target account when there is insufficient balance"
        ) func notTransferAmountInsufficientBalance() async {
            let bank = await Bank(repository: InMemoryRepository())
            await bank.executeTransaction(.deposit(amount: 100, accountID: sourceAccount.id))

            await bank.executeTransaction(
                .transfer(amount: 170, from: sourceAccount.id, to: destinationAccount.id))

            let finalBalanceOfSourceAccount = await bank.balanceFor(sourceAccount.id)
            let finalBalanceOfDestinationAccount = await bank.balanceFor(destinationAccount.id)
            #expect(finalBalanceOfSourceAccount == 100)
            #expect(finalBalanceOfDestinationAccount == 0)
        }
    }

    @Suite("for multiple simultaneous transactions") struct MultipleSimultaniousTransactions {
        let account1 = Account()
        let account2 = Account()
        let account3 = Account()

        @Test(
            "deposit and transfor money for two transactions correctly",
            arguments: [
                0,
                10,
                100,
                1000,
            ]) func asyncDepositAndTransferScenario(delay: UInt32) async
        {
            let bank = await Bank(repository: InMemoryRepository(delay: delay))

            async let t1 = startTransfer1(using: bank)
            usleep(10_000)
            async let t2 = startTransfer2(using: bank)
            await t1.value
            await t2.value

            let account1Balance = await bank.balanceFor(account1.id)
            let account2Balance = await bank.balanceFor(account2.id)

            #expect(account1Balance == 125)
            #expect(account2Balance == 175)
        }

        @Test(arguments: [
            0,
            10,
            100,
            1000,
        ]) func `triangle transfer`(delay: UInt32) async {
            let bank = await Bank(repository: InMemoryRepository(delay: delay))

            async let t3 = startTransfer3(using: bank)
            usleep(10_000)
            async let t4 = startTransfer4(using: bank)
            usleep(10_000)
            async let t5 = startTransfer5(using: bank)
            await t3.value
            await t4.value
            await t5.value

            let account1Balance = await bank.balanceFor(account1.id)
            let account2Balance = await bank.balanceFor(account2.id)
            let account3Balance = await bank.balanceFor(account2.id)

            #expect(account1Balance == 100)
            #expect(account2Balance == 100)
            #expect(account3Balance == 100)
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

        private func startTransfer(using bank: Bank, transactions: [Transaction]) -> Task<
            Void, Never
        > {
            Task {
                for transaction in transactions {
                    await bank.executeTransaction(transaction)
                }
            }
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
