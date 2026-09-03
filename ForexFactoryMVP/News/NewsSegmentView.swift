import SwiftUI
import SafariServices

struct NewsSegmentView: View {
    let segment: NewsSegment
    let model: NewsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let author = segment.authorName {
                HStack {
                    Text(author).font(.caption.weight(.semibold))
                    if let handle = segment.authorHandle {
                        Text(handle).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if segment.type == .quote {
                quoteText
            } else {
                bilingualText
            }
            ForEach(segment.media.sorted(by: { $0.position < $1.position })) { media in
                NewsMediaView(media: media, model: model)
            }
            ForEach(segment.links.sorted(by: { $0.position < $1.position })) { link in
                NavigationLink {
                    SourceArticleView(link: link, model: model)
                } label: {
                    Label("Read full story", systemImage: "doc.text.magnifyingglass")
                        .font(.callout.weight(.semibold))
                }
            }
            if segment.links.isEmpty, let sourceURL = segment.sourceURL {
                Link("View source", destination: sourceURL).font(.caption)
            }
        }
        .padding(segment.type == .quote ? 12 : 0)
        .background(segment.type == .quote ? Color.secondary.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var bilingualText: some View {
        if let english = segment.text.en, !english.isEmpty {
            Text(english).font(.body)
        }
        if let chinese = segment.text.zhHans, !chinese.isEmpty {
            Text(chinese).font(.body).foregroundStyle(.secondary)
        }
    }

    private var quoteText: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle().fill(Color.accentColor).frame(width: 3)
            VStack(alignment: .leading, spacing: 7) {
                if let english = segment.text.en { Text(english).italic() }
                if let chinese = segment.text.zhHans {
                    Text(chinese).italic().foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SourceArticleView: View {
    let link: NewsSegmentLink
    let model: NewsViewModel

    @State private var document: SourceDocument?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showsPublisher = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if let document, hasReadableBody(document) {
                    article(document)
                } else if isLoading {
                    ProgressView("Collecting publisher article…")
                        .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    fallback
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Full Story")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showsPublisher = true
            } label: {
                Label("Publisher website", systemImage: "safari")
            }
        }
        .sheet(isPresented: $showsPublisher) {
            InAppBrowserView(url: document?.finalURL ?? link.url)
                .ignoresSafeArea()
        }
        .task(id: link.sourceDocument?.id) { await load() }
    }

    @ViewBuilder
    private func article(_ document: SourceDocument) -> some View {
        Text(document.sourceHost ?? link.url.host ?? "Publisher")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        BilingualText(
            english: document.title.en ?? link.sourceDocument?.title.en ?? "Full story",
            chinese: document.title.zhHans,
            englishFont: .title2.bold()
        )
        metadata(document)
        if let imageURL = document.leadImageURL {
            AsyncImage(url: imageURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                ProgressView().frame(maxWidth: .infinity, minHeight: 160)
            }
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        ForEach(Array(bilingualParagraphs(document).enumerated()), id: \.offset) { _, pair in
            VStack(alignment: .leading, spacing: 7) {
                Text(pair.english).font(.body)
                if let chinese = pair.chinese, !chinese.isEmpty {
                    Text(chinese).font(.body).foregroundStyle(.secondary)
                }
            }
        }
        Button {
            showsPublisher = true
        } label: {
            Label("Open publisher website", systemImage: "safari")
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private func metadata(_ document: SourceDocument) -> some View {
        let values = [document.authorName, document.publishedAtSourceText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        if !values.isEmpty {
            Text(values.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var fallback: some View {
        ContentUnavailableView {
            Label("Publisher article unavailable", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text(errorMessage ?? stateMessage)
        } actions: {
            Button("Try again") { Task { await load() } }
            Button("Open publisher website") { showsPublisher = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var stateMessage: String {
        switch document?.state ?? link.sourceDocument?.state {
        case .pending, .processing:
            "The server is still collecting this article."
        case .blocked:
            "The publisher did not allow automatic collection."
        case .failed:
            "The server could not extract a readable article."
        default:
            "You can still read the original page in the app."
        }
    }

    private func load() async {
        guard !isLoading, let id = link.sourceDocument?.id else {
            if link.sourceDocument == nil { errorMessage = "No saved publisher copy is available yet." }
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            document = try await model.sourceDocument(id: id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "The saved article could not be loaded."
        }
    }

    private func hasReadableBody(_ document: SourceDocument) -> Bool {
        document.state == .complete && !(document.body.en ?? "").isEmpty
    }

    private func bilingualParagraphs(
        _ document: SourceDocument
    ) -> [(english: String, chinese: String?)] {
        let english = document.paragraphs.isEmpty
            ? paragraphs(in: document.body.en)
            : document.paragraphs
        let chinese = paragraphs(in: document.body.zhHans)
        if english.count == chinese.count {
            return zip(english, chinese).map { (english: $0.0, chinese: $0.1) }
        }
        return english.enumerated().map { index, paragraph in
            (english: paragraph, chinese: index == english.count - 1 ? document.body.zhHans : nil)
        }
    }

    private func paragraphs(in text: String?) -> [String] {
        guard let text else { return [] }
        return text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct InAppBrowserView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
