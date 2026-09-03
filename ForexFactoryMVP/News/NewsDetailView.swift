import SwiftUI

struct NewsDetailView: View {
    let articleID: String
    let summary: NewsArticleSummary?
    let model: NewsViewModel

    @State private var detail: NewsArticleDetail?
    @State private var comments: [NewsComment] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                if let detail {
                    ForEach(detail.segments.sorted(by: { $0.position < $1.position })) { segment in
                        NewsSegmentView(segment: segment, model: model)
                    }
                    if !comments.isEmpty {
                        Divider()
                        Text("Comments")
                            .font(.title3.bold())
                        ForEach(comments) { NewsCommentCard(comment: $0) }
                    }
                    Link("Open original on Forex Factory", destination: detail.ffURL)
                        .font(.footnote.weight(.semibold))
                }
                if isLoading { ProgressView("Loading Forex Factory detail…") }
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
            .padding()
        }
        .navigationTitle("News Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: articleID) { await load() }
    }

    @ViewBuilder
    private var header: some View {
        let source = detail?.sourceName ?? summary?.sourceName ?? "Forex Factory"
        let title = detail?.title ?? summary?.title
        let teaser = detail?.teaser ?? summary?.teaser
        Text(source)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        BilingualText(
            english: title?.en ?? "Loading…",
            chinese: title?.zhHans,
            englishFont: .title2.bold()
        )
        if detail == nil || detail?.segments.isEmpty == true {
            if let english = teaser?.en, !english.isEmpty {
                Text(english).font(.subheadline).foregroundStyle(.secondary)
            }
            if let chinese = teaser?.zhHans, !chinese.isEmpty {
                Text(chinese).font(.footnote).foregroundStyle(.tertiary)
            }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let loadedDetail = model.v2Detail(id: articleID)
            async let loadedComments = model.comments(id: articleID)
            detail = try await loadedDetail
            let commentEnvelope = try? await loadedComments
            comments = commentEnvelope?.items ?? []
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Please try again."
        }
    }
}
