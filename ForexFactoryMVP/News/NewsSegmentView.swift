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
                    Text(author.uppercased())
                        .font(EditorialTheme.smallCaps)
                        .tracking(0.5)
                    if let handle = segment.authorHandle {
                        Text(handle)
                            .font(EditorialTheme.metadata)
                            .foregroundStyle(EditorialTheme.mutedInk)
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
                .font(EditorialTheme.smallCaps)
                .tracking(0.5)
                .foregroundStyle(EditorialTheme.accent)
                .underline()
                .frame(minHeight: 44, alignment: .leading)
            } else if segment.links.isEmpty,
                      let sourceURL = segment.sourceURL {
                Button("VIEW SOURCE") {
                    browserDestination = SafariDestination(url: sourceURL)
                }
                .font(EditorialTheme.smallCaps)
                .tracking(0.5)
                .foregroundStyle(EditorialTheme.accent)
                .underline()
                .frame(minHeight: 44, alignment: .leading)
            }
        }
        .padding(.leading, segment.type == .quote || segment.type == .social ? 12 : 0)
        .overlay(alignment: .leading) {
            if segment.type == .quote || segment.type == .social {
                Rectangle()
                    .fill(EditorialTheme.accent)
                    .frame(width: 3)
            }
        }
        .sheet(item: $browserDestination) { destination in
            InAppBrowserView(url: destination.url)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var bilingualText: some View {
        if let english = presentation.attributedEnglish {
            Text(english)
                .font(.system(.body, design: segment.type == .article ? .serif : .default))
                .foregroundStyle(EditorialTheme.ink)
                .lineSpacing(4)
                .lineLimit(presentation.lineLimit)
                .environment(\.openURL, OpenURLAction { url in
                    browserDestination = SafariDestination(url: url)
                    return .handled
                })
        }
        if let chinese = segment.text.zhHans, !chinese.isEmpty {
            Text(chinese)
                .font(.body)
                .foregroundStyle(EditorialTheme.mutedInk)
                .lineSpacing(3)
                .lineLimit(presentation.lineLimit)
        }
    }

    private var quoteText: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle().fill(EditorialTheme.accent).frame(width: 3)
            VStack(alignment: .leading, spacing: 7) {
                if let english = presentation.attributedEnglish {
                    Text(english)
                        .italic()
                        .foregroundStyle(EditorialTheme.ink)
                        .lineSpacing(4)
                        .lineLimit(presentation.lineLimit)
                        .environment(\.openURL, OpenURLAction { url in
                            browserDestination = SafariDestination(url: url)
                            return .handled
                        })
                }
                if let chinese = segment.text.zhHans, !chinese.isEmpty {
                    Text(chinese)
                        .italic()
                        .foregroundStyle(EditorialTheme.mutedInk)
                        .lineSpacing(3)
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
