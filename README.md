# Async Bank kata

## The Bank scenario
This kata describes a Bank. The Bank supports multiple simultaneous clients. For this reason, the `Bank` is implemented as an `actor`: this ensures that all operations are thread safe.

The bank is backed by a `AccountRepository` that holds accounts. An `Account` is an account ID as well as a balance. In the case of the tests this is an in memory store, but it simulates a database. Interaction with the repository is asynchronous.

The test scenario simulates two clients posting transactions to the `Bank`. And even though the end state when both transactions clear is predictable, it may not always reach that state. In other words, this test is flaky. Its your job to:
* find out why this is happening;
* provide a solution that makes the test no longer flaky.

### Note:
Currently the tests most likely pass. However, should you:
* Add additional delays to the parameterized test, you'll notice that the tests are more and more likely to fail. (You can use Xcode to run the tests multiple times)
* Remove the `usleep` (microsleep) between starting the two tasks, will most likely have every test fail with a `delay` > 0 (and even delay == 0 is not safe).

## Asynchronicity is hard
This kata is meant to experiment with asynchronicity. Even though Swift provides strict concurrency checking and claims to prevent race conditions, this example shows how this can go wrong.
