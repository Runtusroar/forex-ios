import Foundation
import Observation

@Observable
@MainActor
final class CalendarViewModel {
    private let makeAPI: @MainActor @Sendable () throws -> any ForexAPI
    private let cache: ResponseCache
    private let refreshLoop: RefreshLoop
    private var activationTask: Task<Void, Never>?

    var events: [CalendarEvent] = []
    var isRefreshing = false
    var staleSince: Date?
    var errorMessage: String?

    init(
        api: any ForexAPI,
        cache: ResponseCache,
        refreshLoop: RefreshLoop = RefreshLoop()
    ) {
        makeAPI = { api }
        self.cache = cache
        self.refreshLoop = refreshLoop
    }

    init(
        settings: AppSettings,
        cache: ResponseCache,
        refreshLoop: RefreshLoop = RefreshLoop()
    ) {
        makeAPI = {
            let credentials = try settings.credentials()
            return APIClient(baseURL: credentials.baseURL, apiKey: credentials.apiKey)
        }
        self.cache = cache
        self.refreshLoop = refreshLoop
    }

    func activate() {
        guard activationTask == nil else { return }
        activationTask = Task { [weak self] in
            guard let self else { return }
            await loadCachedData()
            guard !Task.isCancelled else { return }
            refreshLoop.start { [weak self] in await self?.refresh() }
        }
    }

    func deactivate() {
        activationTask?.cancel()
        activationTask = nil
        refreshLoop.stop()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let now = Date()
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
            let envelope = try await makeAPI().calendar(from: start, to: end)
            events = envelope.items.sorted { $0.eventAt < $1.eventAt }
            staleSince = nil
            errorMessage = nil
            try await cache.save(envelope, as: .calendar)
        } catch {
            errorMessage = events.isEmpty
                ? readableMessage(for: error)
                : "Unable to refresh. Showing saved data."
        }
    }

    func loadCachedData() async {
        guard let envelope = try? await cache.load(.calendar, as: CalendarEnvelope.self) else {
            return
        }
        events = envelope.items.sorted { $0.eventAt < $1.eventAt }
        staleSince = envelope.generatedAt
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Unable to load the calendar."
    }
}
