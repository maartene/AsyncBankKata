import Foundation

/// A small FIFO global transaction queue helper for serializing work inside an actor.
///
/// Usage:
///   await queue.acquire()
///   defer { queue.release() }
///
/// acquire() suspends if another holder currently owns the queue; release() resumes the next waiter.
actor GlobalTransactionQueue {
    private var locked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init() {}

    func acquire() async {
        if !locked {
            locked = true
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            waiters.append(continuation)
        }

        locked = true
    }

    func release() {
        if !waiters.isEmpty {
            let next = waiters.removeFirst()
            next.resume()
            return
        }

        locked = false
    }
}
