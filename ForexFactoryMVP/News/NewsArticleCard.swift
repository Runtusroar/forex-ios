import SwiftUI

struct NewsArticleCard: View {
    let article: NewsArticleSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(article.sourceName ?? "Forex Factory")
                    .font(EditorialTheme.metadata.weight(.bold))
                    .foregroundStyle(EditorialTheme.ink)
                if let date = article.publishedAt {
                    Text("|").foregroundStyle(EditorialTheme.rule)
                    Text(EditorialDateFormatter.newsTime(date))
                        .font(EditorialTheme.metadata)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
                Spacer(minLength: 0)
            }
            BilingualText(
                english: article.title.en ?? "Untitled",
                chinese: article.title.zhHans,
                role: .sectionHeadline
            )
            if let thumbnailURL = article.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .failure:
                        EditorialTheme.subtleSurface.overlay { Image(systemName: "photo") }
                    default:
                        EditorialTheme.subtleSurface.overlay { ProgressView() }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 170, maxHeight: 170)
                .clipped()
            }
            bilingualTeaser
            HStack(spacing: 12) {
                if let impact = article.breakingImpact { ImpactBadge(impact: impact) }
                Text("COMMENTS \(article.commentCount)")
                if article.isExcerpt { Text("EXCERPT") }
                Spacer()
            }
            .font(EditorialTheme.smallCaps)
            .tracking(0.3)
            .foregroundStyle(EditorialTheme.mutedInk)
            EditorialRule()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var bilingualTeaser: some View {
        if let english = article.teaser.en, !english.isEmpty {
            Text(english)
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(EditorialTheme.ink.opacity(0.86))
                .lineSpacing(3)
                .lineLimit(3)
        }
        if let chinese = article.teaser.zhHans, !chinese.isEmpty {
            Text(chinese)
                .font(.footnote)
                .foregroundStyle(EditorialTheme.mutedInk)
                .lineSpacing(2)
                .lineLimit(3)
        }
    }
}
