import Foundation
import Observation

@Observable
@MainActor
final class CalendarViewModel {
    private let makeAPI: @MainActor @Sendable () throws -> any ForexAPI
    private let cache: ResponseCache
    private let refreshLoop: RefreshLoop
    private let now: @Sendable () -> Date
    private var activationTask: Task<Void, Never>?

    var events: [CalendarEvent] = []
    var isRefreshing = false
    var lastUpdatedAt: Date?
    var staleSince: Date?
    var errorMessage: String?

    init(
        api: any ForexAPI,
        cache: ResponseCache,
        refreshLoop: RefreshLoop = RefreshLoop(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        makeAPI = { api }
        self.cache = cache
        self.refreshLoop = refreshLoop
        self.now = now
    }

    init(
        settings: AppSettings,
        cache: ResponseCache,
        refreshLoop: RefreshLoop = RefreshLoop(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        makeAPI = {
            let credentials = try settings.credentials()
            return APIClient(baseURL: credentials.baseURL, apiKey: credentials.apiKey)
        }
        self.cache = cache
        self.refreshLoop = refreshLoop
        self.now = now
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
            let current = now()
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
            let start = calendar.startOfDay(for: current)
            let end = calendar.date(byAdding: .day, value: 8, to: start) ?? current
            let envelope = try await makeAPI().calendar(from: start, to: end)
            events = envelope.items.sorted(by: calendarEventPrecedes)
            lastUpdatedAt = envelope.generatedAt
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
        events = envelope.items.sorted(by: calendarEventPrecedes)
        lastUpdatedAt = envelope.generatedAt
        staleSince = envelope.generatedAt
    }

    func detail(for event: CalendarEvent) async throws -> CalendarDetail {
        try await makeAPI().calendarDetail(id: event.sourceID)
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Unable to load the calendar."
    }

    private func calendarEventPrecedes(_ lhs: CalendarEvent, _ rhs: CalendarEvent) -> Bool {
        let lhsDay = EditorialDateFormatter.calendarDay(lhs.eventAt)
        let rhsDay = EditorialDateFormatter.calendarDay(rhs.eventAt)
        if lhsDay != rhsDay { return lhsDay < rhsDay }
        if lhs.sourcePosition != rhs.sourcePosition {
            return lhs.sourcePosition < rhs.sourcePosition
        }
        return lhs.eventAt < rhs.eventAt
    }
}
