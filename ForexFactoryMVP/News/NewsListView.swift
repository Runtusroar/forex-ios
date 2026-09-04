import SwiftUI

struct NewsListView: View {
    @Bindable var model: NewsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                EditorialTheme.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                    content
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(EditorialTheme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar { toolbarContent }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isEmpty, !model.isRefreshing {
            ScrollView {
                newspaperHeader
                ContentUnavailableView(
                    model.selectedSection == .latestComments ? "No comments" : "No news",
                    systemImage: model.selectedSection == .latestComments ? "text.bubble" : "newspaper",
                    description: Text("Pull to refresh or check the server details in Settings.")
                )
                .foregroundStyle(EditorialTheme.ink)
                .padding(.top, 40)
            }
            .refreshable { await model.refresh() }
        } else {
            List {
                newspaperHeader
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(EditorialTheme.paper)
                if model.selectedSection == .latestComments {
                    ForEach(model.currentComments) { comment in
                        NavigationLink {
                            NewsDetailView(articleID: comment.articleID, summary: nil, model: model)
                        } label: {
                            NewsCommentCard(comment: comment)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(EditorialTheme.paper)
                    }
                } else {
                    ForEach(model.currentArticles) { article in
                        NavigationLink {
                            NewsDetailView(articleID: article.sourceID, summary: article, model: model)
                        } label: {
                            NewsArticleCard(article: article)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(EditorialTheme.paper)
                    }
                }
                if model.canLoadMore {
                    HStack {
                        Spacer()
                        if model.isLoadingMore { ProgressView() } else { Text("Load more") }
                        Spacer()
                    }
                    .font(.footnote)
                    .foregroundStyle(EditorialTheme.mutedInk)
                    .listRowSeparator(.hidden)
                    .listRowBackground(EditorialTheme.paper)
                    .task { await model.loadMore() }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(EditorialTheme.paper)
            .refreshable { await model.refresh() }
        }
    }

    private var newspaperHeader: some View {
        VStack(spacing: 10) {
            EditorialMasthead(section: "News")
                .padding(.horizontal)
                .padding(.top, 8)
            NewsSectionPicker(model: model)
        }
        .background(EditorialTheme.paper)
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
