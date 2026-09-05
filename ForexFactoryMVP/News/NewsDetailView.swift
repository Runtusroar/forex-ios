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
    @State private var commentsError: String?
    @State private var isLoadingComments = false
    @State private var commentsComplete: Bool?
    @State private var commentsNextCursor: String?
    @State private var failedCommentsCursor: String?
    @State private var browserDestination: NewsSourceDestination?

    private var mediaPresentation: NewsDetailMediaPresentation {
        NewsDetailMediaPresentation(detail: detail, summary: summary)
    }

    var body: some View {
        ZStack {
            EditorialTheme.paper.ignoresSafeArea()
            ScrollView {
                // Eager layout keeps loaded text and image heights stable when reversing scroll direction.
                VStack(alignment: .leading, spacing: 0) {
                    articleContent
                    commentsSection
                }
            }
        }
        .foregroundStyle(EditorialTheme.ink)
        .tint(EditorialTheme.accent)
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(EditorialTheme.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .environment(\.openURL, OpenURLAction { url in
            browserDestination = NewsSourceDestination(url: url)
            return .handled
        })
        .sheet(item: $browserDestination) { destination in
            NewsSourceBrowser(url: destination.url)
                .ignoresSafeArea()
        }
        .task(id: articleID) { await load() }
    }

    private var articleContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            fallbackThumbnail
            if let detail {
                ForEach(detail.segments.sorted(by: { $0.position < $1.position })) { segment in
                    NewsSegmentView(segment: segment, model: model)
                }
            }
            if let errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detail == nil ? "Unable to load article" : "Unable to refresh article")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(EditorialTheme.mutedInk)
                    Button("Retry article") {
                        Task {
                            await loadArticle()
                            await refreshProcessingMedia()
                        }
                    }
                        .frame(minHeight: 44)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EditorialTheme.accent)
                }
            }
            if let url = detail?.ffURL ?? summary?.ffURL {
                Link(destination: url) {
                    Label("Read original on Forex Factory", systemImage: "arrow.up.right")
                        .font(.subheadline.weight(.medium))
                        .frame(minHeight: 44, alignment: .leading)
                }
                .foregroundStyle(EditorialTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, EditorialSpacing.content)
    }

    private var header: some View {
        let source = detail?.sourceName ?? summary?.sourceName ?? "Forex Factory"
        let title = detail?.title ?? summary?.title
        let teaser = detail?.teaser ?? summary?.teaser
        return VStack(alignment: .leading, spacing: EditorialSpacing.content) {
            VStack(alignment: .leading, spacing: 4) {
                Text(source)
                    .font(.subheadline.weight(.semibold))
                if let date = detail?.publishedAt ?? summary?.publishedAt {
                    Text(EditorialDateFormatter.timestamp(date))
                        .font(.caption)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
            }
            Text(english(title?.en) ?? (detail == nil && summary == nil ? "Loading article…" : "English headline unavailable."))
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if detail == nil || detail?.segments.isEmpty == true {
                if let teaser = english(teaser?.en) {
                    Text(teaser)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundStyle(EditorialTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                } else if detail?.segments.isEmpty == true {
                    Text("English article text unavailable. Read the original for the source report.")
                        .font(.body)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
            }
        }
    }

    private var commentsPresentation: NewsCommentsPresentation? {
        commentsComplete.map { complete in
            NewsCommentsPresentation(
                loadedCount: comments.count,
                totalCount: detail?.commentCount ?? summary?.commentCount ?? comments.count,
                commentsComplete: complete,
                nextCursor: commentsNextCursor
            )
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: EditorialSpacing.related) {
                Label("Comments", systemImage: "text.bubble")
                    .font(.headline)
                if let count = detail?.commentCount ?? summary?.commentCount {
                    Text("\(count)")
                        .font(.subheadline.monospacedDigit())
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(EditorialTheme.accent)
            .padding(.horizontal, EditorialSpacing.page)
            .padding(.vertical, EditorialSpacing.content)
            .background(EditorialTheme.subtleSurface)
            .overlay(alignment: .top) {
                Rectangle().fill(EditorialTheme.accent.opacity(0.5)).frame(height: 1)
            }
            .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: EditorialSpacing.inline) {
                if let presentation = commentsPresentation, presentation.isPartial {
                    Text(presentation.collectionLabel)
                        .font(.caption)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
            }
            .padding(.horizontal, EditorialSpacing.page)
            .padding(.vertical, EditorialSpacing.related)

            NewsCommentThreadView(comments: comments)
                .padding(.horizontal, EditorialSpacing.page)
            VStack(alignment: .leading, spacing: 8) {
                if let commentsError {
                    Text("Unable to load comments")
                        .font(.headline)
                    Text(commentsError)
                        .font(.subheadline)
                        .foregroundStyle(EditorialTheme.mutedInk)
                    Button("Retry comments") {
                        Task { await loadComments(cursor: failedCommentsCursor) }
                    }
                    .frame(minHeight: 44)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EditorialTheme.accent)
                } else {
                    if comments.isEmpty, let complete = commentsComplete {
                        let totalCount = detail?.commentCount ?? summary?.commentCount ?? 0
                        Text(complete && totalCount == 0 ? "No comments yet." : "Comments are not available yet.")
                            .font(.body)
                            .foregroundStyle(EditorialTheme.mutedInk)
                    }
                    if let cursor = commentsNextCursor {
                        Button("Load more comments") { Task { await loadComments(cursor: cursor) } }
                            .frame(minHeight: 44)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EditorialTheme.accent)
                    } else if commentsPresentation?.isPartial == true {
                        Text("More comments may appear as collection finishes.")
                            .font(.subheadline)
                            .foregroundStyle(EditorialTheme.mutedInk)
                        Button("Refresh comments") { Task { await loadComments() } }
                            .frame(minHeight: 44)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EditorialTheme.accent)
                    }
                }
            }
            .disabled(isLoadingComments)
            .padding(.horizontal, EditorialSpacing.page)
            .padding(.top, EditorialSpacing.related)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, EditorialSpacing.section)
        .background(EditorialTheme.paper)
        .accessibilityIdentifier("article-discussion")
    }

    @ViewBuilder
    private var fallbackThumbnail: some View {
        if let url = mediaPresentation.fallbackThumbnailURL {
            NewsRemoteImage(url: url, placeholderHeight: 140)
                .frame(maxWidth: .infinity)
            .accessibilityLabel("Article thumbnail")
        }
    }

    private func english(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private func load() async {
        async let article: Void = loadArticle()
        async let discussion: Void = loadComments()
        _ = await (article, discussion)
        guard !Task.isCancelled else { return }
        await refreshProcessingMedia()
    }

    private func loadArticle() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let loadedDetail = try await model.v2Detail(id: articleID)
            try Task.checkCancellation()
            detail = loadedDetail
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Please try again."
        }
    }

    private func loadComments(cursor: String? = nil) async {
        guard !isLoadingComments else { return }
        isLoadingComments = true
        commentsError = nil
        defer { isLoadingComments = false }
        do {
            let envelope = try await model.comments(id: articleID, cursor: cursor)
            try Task.checkCancellation()
            comments = NewsCommentsPresentation.appendingPage(envelope.items, to: cursor == nil ? [] : comments)
            commentsComplete = envelope.commentsComplete
            commentsNextCursor = envelope.nextCursor
        } catch {
            guard !Task.isCancelled else { return }
            failedCommentsCursor = cursor
            commentsError = comments.isEmpty
                ? "The article is still available. Please try the discussion again."
                : "Showing loaded comments. Please try again for the remaining discussion."
        }
    }

    private func refreshProcessingMedia() async {
        for _ in 0 ..< 5 {
            guard mediaPresentation.hasProcessingMedia else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                try Task.checkCancellation()
                let refreshed = try await model.v2Detail(id: articleID)
                try Task.checkCancellation()
                detail = refreshed
            } catch {
                return
            }
        }
    }
}
