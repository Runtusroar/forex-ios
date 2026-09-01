import Foundation
import Observation

@Observable
@MainActor
final class NewsViewModel {
    private let makeAPI: @MainActor @Sendable () throws -> any ForexAPI
    private let cache: ResponseCache
    private let refreshLoop: RefreshLoop
    private var activationTask: Task<Void, Never>?

    var items: [NewsItem] = []
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
            let envelope = try await makeAPI().news(limit: 50)
            items = Self.sorted(envelope.items)
            staleSince = nil
            errorMessage = nil
            try await cache.save(envelope, as: .news)
        } catch {
            errorMessage = items.isEmpty
                ? readableMessage(for: error)
                : "Unable to refresh. Showing saved data."
        }
    }

    func detail(id: String) async throws -> NewsItem {
        try await makeAPI().newsDetail(id: id)
    }

    func loadCachedData() async {
        guard let envelope = try? await cache.load(.news, as: NewsEnvelope.self) else {
            return
        }
        items = Self.sorted(envelope.items)
        staleSince = envelope.generatedAt
    }

    private static func sorted(_ items: [NewsItem]) -> [NewsItem] {
        items.sorted {
            ($0.publishedAt ?? $0.firstSeenAt) > ($1.publishedAt ?? $1.firstSeenAt)
        }
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Unable to load news."
    }
}
