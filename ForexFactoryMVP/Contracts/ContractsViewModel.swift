import Foundation
import Observation

@Observable
@MainActor
final class ContractsViewModel {
    private let makeAPI: @MainActor @Sendable () throws -> any ForexAPI
    private let cache: ResponseCache
    private let refreshLoop: RefreshLoop
    private var activationTask: Task<Void, Never>?

    var contracts: [BinanceFuturesContract] = []
    var isRefreshing = false
    var staleSince: Date?
    var errorMessage: String?

    init(
        api: any ForexAPI,
        cache: ResponseCache,
        refreshLoop: RefreshLoop = RefreshLoop(interval: .seconds(5))
    ) {
        makeAPI = { api }
        self.cache = cache
        self.refreshLoop = refreshLoop
    }

    init(
        settings: AppSettings,
        cache: ResponseCache,
        refreshLoop: RefreshLoop = RefreshLoop(interval: .seconds(5))
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
            let envelope = try await makeAPI().topContracts(limit: 20)
            contracts = Self.sorted(envelope.items)
            staleSince = nil
            errorMessage = nil
            try await cache.save(envelope, as: .contracts)
        } catch {
            errorMessage = contracts.isEmpty
                ? readableMessage(for: error)
                : "Unable to refresh. Showing saved data."
        }
    }

    func loadCachedData() async {
        guard let envelope = try? await cache.load(.contracts, as: BinanceContractsEnvelope.self) else {
            return
        }
        contracts = Self.sorted(envelope.items)
        staleSince = envelope.generatedAt
    }

    private static func sorted(_ contracts: [BinanceFuturesContract]) -> [BinanceFuturesContract] {
        contracts.sorted { $0.quoteVolume > $1.quoteVolume }
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Unable to load contracts."
    }
}
