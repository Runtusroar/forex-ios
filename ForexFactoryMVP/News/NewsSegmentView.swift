import SwiftUI

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
            if let sourceURL = segment.sourceURL {
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
