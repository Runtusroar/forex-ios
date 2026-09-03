import SwiftUI

struct NewsListView: View {
    @Bindable var model: NewsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NewsSectionPicker(model: model)
                ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                content
            }
            .navigationTitle("News")
            .toolbar { toolbarContent }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isEmpty, !model.isRefreshing {
            ContentUnavailableView(
                model.selectedSection == .latestComments ? "No comments" : "No news",
                systemImage: model.selectedSection == .latestComments ? "text.bubble" : "newspaper",
                description: Text("Pull to refresh or check the server details in Settings.")
            )
        } else {
            List {
                if model.selectedSection == .latestComments {
                    ForEach(model.currentComments) { comment in
                        NavigationLink {
                            NewsDetailView(articleID: comment.articleID, summary: nil, model: model)
                        } label: {
                            NewsCommentCard(comment: comment)
                        }
                    }
                } else {
                    ForEach(model.currentArticles) { article in
                        NavigationLink {
                            NewsDetailView(articleID: article.sourceID, summary: article, model: model)
                        } label: {
                            NewsArticleCard(article: article)
                        }
                    }
                }
                if model.canLoadMore {
                    HStack {
                        Spacer()
                        if model.isLoadingMore { ProgressView() } else { Text("Load more") }
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
                    .task { await model.loadMore() }
                }
            }
            .listStyle(.plain)
            .refreshable { await model.refresh() }
        }
    }

    private var isEmpty: Bool {
        model.selectedSection == .latestComments
            ? model.currentComments.isEmpty
            : model.currentArticles.isEmpty
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if model.selectedSection != .latestComments {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("All impact") { Task { await model.setImpactFilter(nil) } }
                    Button("High impact") { Task { await model.setImpactFilter(.high) } }
                    Button("Medium impact") { Task { await model.setImpactFilter(.medium) } }
                    Button("Low impact") { Task { await model.setImpactFilter(.low) } }
                } label: {
                    Label(impactFilterLabel, systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        if model.isRefreshing {
            ToolbarItem(placement: .topBarTrailing) { ProgressView() }
        }
    }

    private var impactFilterLabel: String {
        switch model.impactFilter {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        default: "All"
        }
    }
}
