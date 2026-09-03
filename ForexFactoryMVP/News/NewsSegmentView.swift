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

    init(segment: NewsSegment) {
        let fullStory = segment.links
            .sorted(by: { $0.position < $1.position })
            .first(where: { $0.kind == .fullStory })
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

        guard let english = segment.text.en, !english.isEmpty else {
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

    @State private var browserDestination: SafariDestination?

    private var presentation: NewsSegmentPresentationModel {
        NewsSegmentPresentationModel(segment: segment)
    }

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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let url = presentation.primaryExternalURL {
                            browserDestination = SafariDestination(url: url)
                        }
                    }
            }
            if let action = presentation.externalAction {
                Button(action.label) {
                    browserDestination = SafariDestination(url: action.url)
                }
                .font(.callout.weight(.semibold))
            } else if segment.links.isEmpty,
                      let sourceURL = segment.sourceURL {
                Button("View source") {
                    browserDestination = SafariDestination(url: sourceURL)
                }
                .font(.caption)
            }
        }
        .padding(segment.type == .quote ? 12 : 0)
        .background(segment.type == .quote ? Color.secondary.opacity(0.08) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .sheet(item: $browserDestination) { destination in
            InAppBrowserView(url: destination.url)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var bilingualText: some View {
        if let english = presentation.attributedEnglish {
            Text(english)
                .font(.body)
                .lineLimit(presentation.lineLimit)
                .environment(\.openURL, OpenURLAction { url in
                    browserDestination = SafariDestination(url: url)
                    return .handled
                })
        }
        if let chinese = segment.text.zhHans, !chinese.isEmpty {
            Text(chinese)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(presentation.lineLimit)
        }
    }

    private var quoteText: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle().fill(Color.accentColor).frame(width: 3)
            VStack(alignment: .leading, spacing: 7) {
                if let english = presentation.attributedEnglish {
                    Text(english)
                        .italic()
                        .lineLimit(presentation.lineLimit)
                        .environment(\.openURL, OpenURLAction { url in
                            browserDestination = SafariDestination(url: url)
                            return .handled
                        })
                }
                if let chinese = segment.text.zhHans, !chinese.isEmpty {
                    Text(chinese)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(presentation.lineLimit)
                }
            }
        }
    }
}

private struct SafariDestination: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct InAppBrowserView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
