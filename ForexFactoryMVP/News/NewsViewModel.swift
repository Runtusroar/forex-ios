import Foundation
import Observation

private struct NewsContentKey: Hashable, Sendable {
    let section: NewsSectionID
    let impact: Impact?
}

private struct ArticlePageState: Sendable {
    var items: [NewsArticleSummary] = []
    var nextCursor: String?
    var generatedAt: Date?
    var isLoaded = false
}

private struct CommentPageState: Sendable {
    var items: [NewsComment] = []
    var nextCursor: String?
    var generatedAt: Date?
    var isLoaded = false
}

@Observable
@MainActor
final class NewsViewModel {
    private let makeAPI: @MainActor @Sendable () throws -> any ForexAPI
    private let cache: ResponseCache
    private let refreshLoop: RefreshLoop
    private var activationTask: Task<Void, Never>?
    private var articleStates: [NewsContentKey: ArticlePageState] = [:]
    private var commentState = CommentPageState()

    var sections: [NewsSection] = NewsViewModel.fallbackSections
    var selectedSection: NewsSectionID = .latest
    var impactFilter: Impact?
    var isRefreshing = false
    var isLoadingMore = false
    var staleSince: Date?
    var errorMessage: String?

    var currentArticles: [NewsArticleSummary] {
        guard selectedSection != .latestComments else { return [] }
        return articleStates[currentKey]?.items ?? []
    }

    var currentComments: [NewsComment] {
        selectedSection == .latestComments ? commentState.items : []
    }

    var canLoadMore: Bool {
        if selectedSection == .latestComments {
            return commentState.nextCursor != nil
        }
        return articleStates[currentKey]?.nextCursor != nil
    }

    // Kept until the legacy list view is replaced by the News V2 UI.
    var items: [NewsItem] = []

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

    func select(_ section: NewsSectionID) async {
        guard selectedSection != section else {
            if !isCurrentContentLoaded { await refresh() }
            return
        }
        selectedSection = section
        if section == .latestComments {
            impactFilter = nil
        }
        syncStaleness()
        await loadCachedData()
        await refresh()
    }

    func setImpactFilter(_ impact: Impact?) async {
        let supportedImpact: Impact?
        switch impact {
        case .high, .medium, .low:
            supportedImpact = impact
        default:
            supportedImpact = nil
        }
        guard selectedSection != .latestComments, impactFilter != supportedImpact else { return }
        impactFilter = supportedImpact
        syncStaleness()
        await loadCachedData()
        await refresh()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let section = selectedSection
        let impact = impactFilter
        let key = NewsContentKey(section: section, impact: impact)
        do {
            let api = try makeAPI()
            if let metadata = try? await api.newsSections(), !metadata.items.isEmpty {
                sections = metadata.items
            }
            if section == .latestComments {
                let envelope = try await api.latestComments(limit: 50, cursor: nil)
                guard selectedSection == section else { return }
                commentState = CommentPageState(
                    items: Self.sorted(envelope.items),
                    nextCursor: envelope.nextCursor,
                    generatedAt: envelope.generatedAt,
                    isLoaded: true
                )
                try await cache.save(envelope, as: .news(section: section, impact: nil))
            } else {
                let envelope = try await api.news(
                    section: section,
                    impact: impact,
                    limit: 50,
                    cursor: nil
                )
                guard currentKey == key else { return }
                articleStates[key] = ArticlePageState(
                    items: Self.sorted(envelope.items),
                    nextCursor: envelope.nextCursor,
                    generatedAt: envelope.generatedAt,
                    isLoaded: true
                )
                try await cache.save(envelope, as: .news(section: section, impact: impact))
            }
            staleSince = nil
            errorMessage = nil
        } catch {
            let hasRows = section == .latestComments
                ? !commentState.items.isEmpty
                : !(articleStates[key]?.items.isEmpty ?? true)
            errorMessage = hasRows
                ? "Unable to refresh. Showing saved data."
                : readableMessage(for: error)
        }
    }

    func loadMore() async {
        guard !isLoadingMore else { return }
        let section = selectedSection
        let impact = impactFilter
        let key = NewsContentKey(section: section, impact: impact)
        let cursor = section == .latestComments
            ? commentState.nextCursor
            : articleStates[key]?.nextCursor
        guard let cursor else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let api = try makeAPI()
            if section == .latestComments {
                let envelope = try await api.latestComments(limit: 50, cursor: cursor)
                guard selectedSection == section else { return }
                commentState.items = Self.appendingUnique(
                    commentState.items,
                    envelope.items,
                    id: \NewsComment.commentID
                )
                commentState.nextCursor = envelope.nextCursor
                commentState.generatedAt = envelope.generatedAt
            } else {
                let envelope = try await api.news(
                    section: section,
                    impact: impact,
                    limit: 50,
                    cursor: cursor
                )
                guard currentKey == key else { return }
                var state = articleStates[key] ?? ArticlePageState()
                state.items = Self.appendingUnique(
                    state.items,
                    envelope.items,
                    id: \NewsArticleSummary.sourceID
                )
                state.nextCursor = envelope.nextCursor
                state.generatedAt = envelope.generatedAt
                articleStates[key] = state
            }
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load more. Please try again."
        }
    }

    func v2Detail(id: String) async throws -> NewsArticleDetail {
        try await makeAPI().newsV2Detail(id: id)
    }

    func comments(id: String, cursor: String? = nil) async throws -> NewsCommentsEnvelope {
        try await makeAPI().articleComments(id: id, limit: 50, cursor: cursor)
    }

    func mediaData(path: String) async throws -> Data {
        try await makeAPI().mediaData(path: path)
    }

    // Kept until the legacy detail view is replaced by the News V2 UI.
    func detail(id: String) async throws -> NewsItem {
        try await makeAPI().newsDetail(id: id)
    }

    func loadCachedData() async {
        let section = selectedSection
        let impact = impactFilter
        let key = NewsContentKey(section: section, impact: impact)
        if section == .latestComments {
            guard !commentState.isLoaded,
                  let envelope = try? await cache.load(
                      .news(section: section, impact: nil),
                      as: NewsCommentsEnvelope.self
                  )
            else { return }
            commentState = CommentPageState(
                items: Self.sorted(envelope.items),
                nextCursor: envelope.nextCursor,
                generatedAt: envelope.generatedAt,
                isLoaded: true
            )
            staleSince = envelope.generatedAt
        } else {
            guard articleStates[key]?.isLoaded != true,
                  let envelope = try? await cache.load(
                      .news(section: section, impact: impact),
                      as: NewsArticlesEnvelope.self
                  )
            else { return }
            articleStates[key] = ArticlePageState(
                items: Self.sorted(envelope.items),
                nextCursor: envelope.nextCursor,
                generatedAt: envelope.generatedAt,
                isLoaded: true
            )
            staleSince = envelope.generatedAt
        }
    }

    private var currentKey: NewsContentKey {
        NewsContentKey(section: selectedSection, impact: impactFilter)
    }

    private var isCurrentContentLoaded: Bool {
        if selectedSection == .latestComments { return commentState.isLoaded }
        return articleStates[currentKey]?.isLoaded == true
    }

    private func syncStaleness() {
        staleSince = selectedSection == .latestComments
            ? commentState.generatedAt
            : articleStates[currentKey]?.generatedAt
        errorMessage = nil
    }

    private static func sorted(_ items: [NewsArticleSummary]) -> [NewsArticleSummary] {
        items.sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
    }

    private static func sorted(_ items: [NewsComment]) -> [NewsComment] {
        items.sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
    }

    private static func appendingUnique<Item, ID: Hashable>(
        _ existing: [Item],
        _ incoming: [Item],
        id: KeyPath<Item, ID>
    ) -> [Item] {
        var seen = Set(existing.map { $0[keyPath: id] })
        return existing + incoming.filter { seen.insert($0[keyPath: id]).inserted }
    }

    private func readableMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? "Unable to load news."
    }

    private static let fallbackSections: [NewsSection] = [
        NewsSection(id: .latest, name: .init(en: "Latest", zhHans: "最新"), itemCount: 0, supportsImpactFilter: true),
        NewsSection(id: .hot, name: .init(en: "Hot", zhHans: "热门"), itemCount: 0, supportsImpactFilter: true),
        NewsSection(id: .fundamental, name: .init(en: "Fundamental", zhHans: "基本面"), itemCount: 0, supportsImpactFilter: true),
        NewsSection(id: .technical, name: .init(en: "Technical", zhHans: "技术分析"), itemCount: 0, supportsImpactFilter: true),
        NewsSection(id: .industry, name: .init(en: "Industry", zhHans: "行业"), itemCount: 0, supportsImpactFilter: true),
        NewsSection(id: .entertainment, name: .init(en: "Entertainment", zhHans: "轻松资讯"), itemCount: 0, supportsImpactFilter: true),
        NewsSection(id: .educational, name: .init(en: "Educational", zhHans: "学习"), itemCount: 0, supportsImpactFilter: true),
        NewsSection(id: .latestComments, name: .init(en: "Latest Comments", zhHans: "最新评论"), itemCount: 0, supportsImpactFilter: false),
    ]
}
