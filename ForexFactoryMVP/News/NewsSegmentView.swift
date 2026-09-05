import SafariServices
import SwiftUI

struct NewsSegmentExternalAction: Equatable, Sendable {
    let label: String
    let url: URL
}

struct NewsSegmentPresentationModel: Equatable, Sendable {
    let attributedEnglish: AttributedString?
    let lineLimit: Int?
    let externalAction: NewsSegmentExternalAction?
    let primaryExternalURL: URL?
    let visibleMedia: [NewsMedia]

    init(segment: NewsSegment) {
        let fullStory = segment.links
            .sorted(by: { $0.position < $1.position })
            .first(where: { $0.kind == .fullStory })
        visibleMedia = segment.media
            .sorted(by: { $0.position < $1.position })
            .filter { NewsMediaPresentation(media: $0).state != .unavailable }
        primaryExternalURL = fullStory?.url ?? segment.sourceURL
        lineLimit = segment.presentation.mode == .clamped
            ? segment.presentation.maxLines
            : nil
        if let label = segment.presentation.actionLabel,
           let url = segment.sourceURL,
           !label.isEmpty {
            externalAction = NewsSegmentExternalAction(label: label, url: url)
        } else {
            externalAction = nil
        }

        guard let english = segment.text.en?.trimmingCharacters(in: .whitespacesAndNewlines), !english.isEmpty else {
            attributedEnglish = nil
            return
        }
        var value = AttributedString(english)
        if let fullStory {
            value.append(AttributedString(" ("))
            var linkedLabel = AttributedString(fullStory.label)
            linkedLabel.link = fullStory.url
            value.append(linkedLabel)
            value.append(AttributedString(")"))
        }
        attributedEnglish = value
    }
}

struct NewsSegmentView: View {
    let segment: NewsSegment
    let model: NewsViewModel

    @State private var browserDestination: NewsSourceDestination?

    private var presentation: NewsSegmentPresentationModel {
        NewsSegmentPresentationModel(segment: segment)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if segment.authorName != nil || segment.publishedAt != nil {
                VStack(alignment: .leading, spacing: 4) {
                    if let author = segment.authorName {
                        Text(author)
                            .font(.subheadline.weight(.semibold))
                        if let handle = segment.authorHandle {
                            Text(handle)
                                .font(.caption)
                                .foregroundStyle(EditorialTheme.mutedInk)
                        }
                    }
                    if let date = segment.publishedAt {
                        Text("\(EditorialDateFormatter.publicationDate(date)) · \(EditorialDateFormatter.newsTime(date)) UTC+8")
                            .font(.caption)
                            .foregroundStyle(EditorialTheme.mutedInk)
                    }
                }
            }
            englishText
            ForEach(presentation.visibleMedia) { media in
                NewsMediaView(media: media, model: model)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let url = presentation.primaryExternalURL {
                            browserDestination = NewsSourceDestination(url: url)
                        }
                    }
            }
            if let action = presentation.externalAction {
                sourceButton(action.label, url: action.url)
            } else if segment.links.isEmpty,
                      let sourceURL = segment.sourceURL {
                sourceButton("View source", url: sourceURL)
            }
        }
        .foregroundStyle(EditorialTheme.ink)
        .padding(.leading, segment.type == .quote || segment.type == .social ? 16 : 0)
        .overlay(alignment: .leading) {
            if segment.type == .quote || segment.type == .social {
                Rectangle()
                    .fill(EditorialTheme.rule)
                    .frame(width: 2)
            }
        }
        .sheet(item: $browserDestination) { destination in
            NewsSourceBrowser(url: destination.url)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var englishText: some View {
        if let english = presentation.attributedEnglish {
            Text(english)
                .font(.body)
                .foregroundStyle(EditorialTheme.ink)
                .lineSpacing(6)
                .lineLimit(presentation.lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    browserDestination = NewsSourceDestination(url: url)
                    return .handled
                })
        } else if segment.type == .article || segment.type == .quote || segment.type == .social {
            Text("English text unavailable.")
                .font(.body)
                .foregroundStyle(EditorialTheme.mutedInk)
        }
    }

    private func sourceButton(_ label: String, url: URL) -> some View {
        Button {
            browserDestination = NewsSourceDestination(url: url)
        } label: {
            Label(label, systemImage: "arrow.up.right")
                .font(.subheadline.weight(.medium))
                .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(EditorialTheme.accent)
    }
}

struct NewsSourceDestination: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct NewsSourceBrowser: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
