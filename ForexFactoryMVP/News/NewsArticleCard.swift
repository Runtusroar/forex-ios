import SwiftUI

struct NewsArticleCard: View {
    let article: NewsArticleSummary

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialSpacing.related) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.sourceName ?? "Forex Factory")
                    .font(EditorialTheme.metadata)
                    .foregroundStyle(EditorialTheme.mutedInk)
                if let date = article.publishedAt {
                    Text(EditorialDateFormatter.timestamp(date))
                        .font(EditorialTheme.metadata)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
            }
            ContentText(
                english: article.title.en ?? "Untitled",
                font: .headline
            )
            if let thumbnailURL = article.thumbnailURL {
                NewsRemoteImage(url: thumbnailURL, fillsFrame: true, placeholderHeight: 170)
                .frame(maxWidth: .infinity, minHeight: 170, maxHeight: 170)
                .clipped()
            }
            teaser
            HStack(spacing: 12) {
                if let impact = article.breakingImpact { ImpactBadge(impact: impact) }
                Label("\(article.commentCount) \(article.commentCount == 1 ? "comment" : "comments")", systemImage: "text.bubble")
                if article.isExcerpt { Text("Excerpt") }
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(EditorialTheme.mutedInk)
        }
    }

    @ViewBuilder
    private var teaser: some View {
        if let english = article.teaser.en, !english.isEmpty {
            Text(english)
                .font(.subheadline)
                .foregroundStyle(EditorialTheme.mutedInk)
                .lineSpacing(3)
                .lineLimit(2)
        }
    }
}
