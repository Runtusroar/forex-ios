import SwiftUI

struct NewsListView: View {
    @Bindable var model: NewsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                if model.items.isEmpty, !model.isRefreshing {
                    ContentUnavailableView(
                        "No news",
                        systemImage: "newspaper",
                        description: Text("Add your server details in Settings, then pull to refresh.")
                    )
                } else {
                    List(model.items) { item in
                        NavigationLink {
                            NewsDetailView(item: item, model: model)
                        } label: {
                            NewsCard(item: item)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await model.refresh() }
                }
            }
            .navigationTitle("News")
            .toolbar {
                if model.isRefreshing {
                    ToolbarItem(placement: .topBarTrailing) { ProgressView() }
                }
            }
        }
    }
}

private struct NewsCard: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(item.source ?? "Forex Factory")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(item.publishedAt ?? item.firstSeenAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            BilingualText(english: item.titleEN, chinese: item.titleZH)
            if let summary = item.summaryEN, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            if let summary = item.summaryZH, !summary.isEmpty {
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .lineLimit(3)
            }
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 7)
    }
}
