import Foundation

/// A bounded await even when an SDK operation does not cooperate with cancellation.
/// The losing operation is cancelled; a late result cannot resume the waiter twice.
private final class PlanningTimeoutState<Value>: @unchecked Sendable {
 private let lock = NSLock()
 private var result: Result<Value, Error>?
 private var continuation: CheckedContinuation<Value, Error>?
 private var children: [Task<Void, Never>] = []
 func install(_ continuation: CheckedContinuation<Value, Error>) -> Bool {
  lock.lock()
  if let result { lock.unlock(); continuation.resume(with: result); return false }
  self.continuation = continuation; lock.unlock(); return true
 }
 func attach(_ tasks: [Task<Void, Never>]) {
  lock.lock(); let finished = result != nil
  if !finished { children = tasks }
  lock.unlock()
  if finished { tasks.forEach { $0.cancel() } }
 }
 func finish(_ value: Result<Value, Error>) {
  lock.lock()
  guard result == nil else { lock.unlock(); return }
  result = value
  let waiter = continuation; continuation = nil
  let tasks = children; children = []
  lock.unlock()
  tasks.forEach { $0.cancel() }
  waiter?.resume(with: value)
 }
}
enum PlanningTimeout {
 static func run<Value>(seconds: Double, operation: @escaping () async throws -> Value) async throws -> Value {
  let state = PlanningTimeoutState<Value>()
  return try await withTaskCancellationHandler {
   try await withCheckedThrowingContinuation { continuation in
    guard state.install(continuation) else { return }
    let work = Task { do { state.finish(.success(try await operation())) } catch { state.finish(.failure(error)) } }
    let timeout = Task {
     do { try await Task.sleep(for: .seconds(seconds)); state.finish(.failure(URLError(.timedOut))) }
     catch { }
    }
    state.attach([work, timeout])
   }
  } onCancel: { state.finish(.failure(CancellationError())) }
 }
}
