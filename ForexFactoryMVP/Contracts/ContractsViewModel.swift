import Foundation
import Observation

@Observable
@MainActor
final class ContractsViewModel {
    private let makeAPI: @MainActor @Sendable () throws -> any ForexAPI
    private let cache: ResponseCache
    private let refreshLoop: RefreshLoop
    private var activationTask: Task<Void, Never>?
    private var refreshingMarkets: Set<ContractMarketFilter> = []

    var contracts: [BinanceFuturesContract] = []
    var selectedMarket: ContractMarketFilter = .all
    var lastUpdatedAt: Date?
    var staleSince: Date?
    var errorMessage: String?
    var isRefreshing: Bool { refreshingMarkets.contains(selectedMarket) }

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
        let marketType = selectedMarket
        guard !refreshingMarkets.contains(marketType) else { return }
        refreshingMarkets.insert(marketType)
        defer { refreshingMarkets.remove(marketType) }
        do {
            let envelope = try await makeAPI().topContracts(limit: 20, marketType: marketType)
            guard selectedMarket == marketType else { return }
            contracts = Self.sorted(envelope.items)
            lastUpdatedAt = envelope.generatedAt
            staleSince = nil
            errorMessage = nil
            try await cache.save(envelope, as: .contracts(marketType: marketType))
        } catch {
            guard selectedMarket == marketType else { return }
            errorMessage = contracts.isEmpty
                ? readableMessage(for: error)
                : "Unable to refresh. Showing saved data."
        }
    }

    func select(_ marketType: ContractMarketFilter) async {
        guard selectedMarket != marketType else {
            if contracts.isEmpty { await refresh() }
            return
        }
        selectedMarket = marketType
        contracts = []
        lastUpdatedAt = nil
        staleSince = nil
        errorMessage = nil
        await loadCachedData()
        await refresh()
    }

    func loadCachedData() async {
        guard let envelope = try? await cache.load(
            .contracts(marketType: selectedMarket),
            as: BinanceContractsEnvelope.self
        ) else {
            return
        }
        contracts = Self.sorted(envelope.items)
        lastUpdatedAt = envelope.generatedAt
        staleSince = envelope.generatedAt
    }

    private static func sorted(_ contracts: [BinanceFuturesContract]) -> [BinanceFuturesContract] {
        contracts.sorted { $0.quoteVolume > $1.quoteVolume }
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Unable to load contracts."
    }
}
