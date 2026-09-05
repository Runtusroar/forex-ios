import SwiftUI

struct NewsDetailMediaPresentation: Equatable, Sendable {
    let fallbackThumbnailURL: URL?
    let hasProcessingMedia: Bool

    init(detail: NewsArticleDetail?, summary: NewsArticleSummary?) {
        let mediaStates = detail?.segments.flatMap(\.media).map {
            NewsMediaPresentation(media: $0)
        } ?? []
        let hasDisplayableSegmentMedia = mediaStates.contains(where: \.hasDisplayableImage)
        hasProcessingMedia = mediaStates.contains { $0.state == .processing }

        fallbackThumbnailURL = hasDisplayableSegmentMedia
            ? nil
            : detail?.thumbnailURL ?? summary?.thumbnailURL
    }
}

struct NewsDetailView: View {
    let articleID: String
    let summary: NewsArticleSummary?
    let model: NewsViewModel

    @State private var detail: NewsArticleDetail?
    @State private var comments: [NewsComment] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var mediaPresentation: NewsDetailMediaPresentation {
        NewsDetailMediaPresentation(detail: detail, summary: summary)
    }

    var body: some View {
        ZStack {
            EditorialTheme.paper.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    header
                    fallbackThumbnail
                    if let detail {
                        ForEach(detail.segments.sorted(by: { $0.position < $1.position })) { segment in
                            NewsSegmentView(segment: segment, model: model)
                        }
                        if !comments.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                EditorialRule(weight: .double)
                                Text("COMMENTS")
                                    .font(EditorialTheme.smallCaps)
                                    .tracking(1.2)
                            }
                            ForEach(comments) { NewsCommentCard(comment: $0) }
                        }
                        Link("OPEN ORIGINAL ON FOREX FACTORY", destination: detail.ffURL)
                            .font(EditorialTheme.smallCaps)
                            .tracking(0.5)
                            .foregroundStyle(EditorialTheme.accent)
                            .underline()
                    }
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("LOADING FOREX FACTORY DETAIL…")
                                .font(EditorialTheme.smallCaps)
                        }
                    }
                    if let errorMessage {
                        ContentUnavailableView {
                            Label("Unable to load detail", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Retry") { Task { await load() } }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("ARTICLE")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(EditorialTheme.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: articleID) { await load() }
    }

    @ViewBuilder
    private var header: some View {
        let source = detail?.sourceName ?? summary?.sourceName ?? "Forex Factory"
        let title = detail?.title ?? summary?.title
        let teaser = detail?.teaser ?? summary?.teaser
        HStack(alignment: .firstTextBaseline) {
            Text(source.uppercased())
                .font(EditorialTheme.smallCaps)
                .tracking(0.6)
            Spacer()
            if let date = detail?.publishedAt ?? summary?.publishedAt {
                Text(EditorialDateFormatter.newsTime(date))
                    .font(EditorialTheme.smallCaps)
                    .foregroundStyle(EditorialTheme.accent)
            }
        }
        .padding(.top, 12)
        BilingualText(
            english: title?.en ?? "Loading…",
            chinese: title?.zhHans,
            role: .headline,
            englishFont: .title2.bold()
        )
        if detail == nil || detail?.segments.isEmpty == true {
            if let english = teaser?.en, !english.isEmpty {
                Text(english)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(EditorialTheme.ink.opacity(0.86))
            }
            if let chinese = teaser?.zhHans, !chinese.isEmpty {
                Text(chinese)
                    .font(.footnote)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
        }
        EditorialRule(weight: .strong)
    }

    @ViewBuilder
    private var fallbackThumbnail: some View {
        if let url = mediaPresentation.fallbackThumbnailURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    EmptyView()
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 140)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .background(EditorialTheme.subtleSurface)
            .overlay {
                Rectangle()
                    .stroke(EditorialTheme.rule.opacity(0.35), lineWidth: 0.5)
            }
            .accessibilityLabel("Article thumbnail")
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let loadedDetail = model.v2Detail(id: articleID)
            async let loadedComments = model.comments(id: articleID)
            detail = try await loadedDetail
            let commentEnvelope = try? await loadedComments
            comments = commentEnvelope?.items ?? []
            isLoading = false
            await refreshProcessingMedia()
        } catch {
            isLoading = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Please try again."
        }
    }

    private func refreshProcessingMedia() async {
        for _ in 0 ..< 5 {
            guard mediaPresentation.hasProcessingMedia else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                try Task.checkCancellation()
                detail = try await model.v2Detail(id: articleID)
            } catch {
                return
            }
        }
    }
}
