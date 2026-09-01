import Foundation

@MainActor
final class RefreshLoop {
    typealias Operation = @MainActor @Sendable () async -> Void

    private let interval: Duration
    private var operation: Operation?
    private var loopTask: Task<Void, Never>?
    private var inFlightTask: Task<Void, Never>?

    init(interval: Duration = .seconds(30)) {
        self.interval = interval
    }

    func start(operation: @escaping Operation) {
        stop()
        self.operation = operation
        loopTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await refreshNow()
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
            }
        }
    }

    func refreshNow() async {
        if let inFlightTask {
            await inFlightTask.value
            return
        }
        guard let operation else { return }
        let task = Task { await operation() }
        inFlightTask = task
        await task.value
        inFlightTask = nil
    }

    func stop() {
        loopTask?.cancel()
        inFlightTask?.cancel()
        loopTask = nil
        inFlightTask = nil
        operation = nil
    }

    deinit {
        loopTask?.cancel()
        inFlightTask?.cancel()
    }
}
