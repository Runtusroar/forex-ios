import SwiftUI

struct NewsArticleCard: View {
    let article: NewsArticleSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(article.sourceName ?? "Forex Factory")
                    .font(.caption.weight(.semibold))
                Spacer()
                if let date = article.publishedAt {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            BilingualText(
                english: article.title.en ?? "Untitled",
                chinese: article.title.zhHans
            )
            bilingualTeaser
            if let thumbnailURL = article.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case let .success(image): image.resizable().scaledToFill()
                    case .failure: Color.secondary.opacity(0.1).overlay { Image(systemName: "photo") }
                    default: Color.secondary.opacity(0.1).overlay { ProgressView() }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            HStack(spacing: 10) {
                if let impact = article.breakingImpact { ImpactBadge(impact: impact) }
                Label("\(article.commentCount)", systemImage: "text.bubble")
                if article.isExcerpt { Label("Excerpt", systemImage: "doc.text") }
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var bilingualTeaser: some View {
        if let english = article.teaser.en, !english.isEmpty {
            Text(english)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        if let chinese = article.teaser.zhHans, !chinese.isEmpty {
            Text(chinese)
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .lineLimit(3)
        }
    }
}
