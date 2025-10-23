import Foundation

/// A small FIFO global transaction queue helper for serializing work inside an actor.
///
/// Usage (from an actor):
///   await queue.acquire()
///   defer { queue.release() }
///
/// Invariants and rationale:
/// - `locked` explicitly indicates whether there is a current owner of the queue.
///   - `locked == true` means some task currently holds the global lock and may be
///     performing work. The owner is not represented in `waiters`.
///   - `locked == false` means the queue is free and the next caller to `acquire()`
///     will become the owner immediately.
/// - `waiters` is a FIFO queue of continuations for callers that attempted to acquire
///   while the lock was already held. Only suspended waiters are stored here.
///
/// Why keep `locked` separate from `waiters`?
/// - `waiters.isEmpty` is ambiguous: it can be empty when the queue is free (unlocked)
///   or when someone holds the lock but no other callers are waiting. Having a dedicated
///   `locked` boolean makes ownership explicit and avoids creating continuations for
///   the uncontended (fast) path.
///
/// Behavior:
/// - `acquire()`:
///   - If `locked` is false, set it to true and return immediately (fast path).
///   - Otherwise append a continuation to `waiters` and suspend; when resumed the caller
///     sets `locked = true` and becomes the owner.
/// - `release()`:
///   - If there are queued waiters, remove the first and resume it (that waiter becomes
///     the owner). We keep `locked == true` in this case because ownership transfers.
///   - If no waiters remain, set `locked = false` (the queue becomes free).
///
/// This design keeps the common uncontended path cheap and the ownership semantics explicit.
actor GlobalTransactionQueue {
    // true when an active owner holds the global lock
    private var locked = false
    // suspended acquirers waiting in FIFO order
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

        // when resumed, this task now holds the lock
        locked = true
    }

    /// Synchronous, nonisolated convenience so callers can `defer { queue.release() }`.
    /// This schedules an async message to the actor to run the real release logic.
    nonisolated func release() {
        Task { await self._release() }
    }

    /// Actor-isolated release implementation. This actually manipulates state.
    private func _release() {
        if !waiters.isEmpty {
            let next = waiters.removeFirst()
            // resume the next waiter; it will set `locked = true` when it resumes
            next.resume()
            return
        }

        // no waiters, mark unlocked
        locked = false
    }
}
