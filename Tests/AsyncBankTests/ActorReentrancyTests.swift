import Foundation
import Testing

actor Counter {
    private var count = 0
    private var delay: UInt64 {
        UInt64.random(in: 1_000_000...10_000_000)
    }

    func addOne(taskID: Int = 0) async {
        print("Task \(taskID) - addOne - Adding one")
        print("Task \(taskID) - addOne - Retrieving current count")
        let currentCount = await getCount(taskID: taskID)
        print("Task \(taskID) - addOne - Retrieved current count: \(currentCount)")

        // some other asynchronous work
        print("Task \(taskID) - addOne - Started some asynchronous work")
        try? await Task.sleep(nanoseconds: delay)
        print("Task \(taskID) - addOne - Completed some asynchronous work")

        print("Task \(taskID) - addOne - Setting count to the new value: \(currentCount) + 1")
        count = currentCount + 1
    }

    func getCount(taskID: Int = 0) async -> Int {
        print("Task \(taskID) - getCount - Starting retrieving count")
        try? await Task.sleep(nanoseconds: delay)
        print("Task \(taskID) - getCount - Ending retrieving count: \(count)")
        return count
    }
}

@Suite struct ActorReentrancyTests {
    let counter = Counter()

    @Test func `counter starts at 0`() async {
        #expect(await counter.getCount() == 0)
    }

    @Test func `adding one once sets the counter to 1`() async {
        await counter.addOne()

        #expect(await counter.getCount() == 1)
    }

    @Test func `adding one twelve times the counter to 12`() async {
        for i in 0..<12 {
            await counter.addOne(taskID: i)
        }

        #expect(await counter.getCount() == 12)
    }

    @Test func `adding one six times in parallel leads to 6`() async {
        let tasks = (0..<6).map { taskID in
            Task {
                await counter.addOne(taskID: taskID)
            }
        }

        for task in tasks {
            await task.value
        }

        let result = await counter.getCount()
        #expect(result == 6)
    }
}
