import SwiftUI

struct NewsListView: View {
    @Bindable var model: NewsViewModel
    @State private var isImpactFilterPresented = false
    @State private var path: [NewsRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                EditorialTheme.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                    content
                }
                .accessibilityHidden(isImpactFilterPresented)
                if isImpactFilterPresented {
                    impactFilterOverlay
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: NewsRoute.self) { route in
                switch route {
                case .article(let sourceID):
                    NewsDetailView(
                        articleID: sourceID,
                        summary: model.currentArticles.first { $0.sourceID == sourceID },
                        model: model
                    )
                case .comment(let articleID):
                    NewsDetailView(articleID: articleID, summary: nil, model: model)
                }
            }
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
                    description: Text("Tap the update time to refresh, or check the server details in Settings.")
                )
                .foregroundStyle(EditorialTheme.ink)
                .padding(.top, EditorialSpacing.section)
            }
        } else {
            List {
                newspaperHeader
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(EditorialTheme.paper)
                if model.selectedSection == .latestComments {
                    ForEach(model.currentComments) { comment in
                        Button {
                            path.append(.comment(articleID: comment.articleID))
                        } label: {
                            NewsCommentCard(comment: comment)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        .listRowSeparatorTint(EditorialTheme.rule)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
                        .listRowBackground(EditorialTheme.surface)
                    }
                } else {
                    ForEach(model.currentArticles) { article in
                        Button {
                            path.append(.article(sourceID: article.sourceID))
                        } label: {
                            NewsArticleCard(article: article)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                        .listRowSeparatorTint(EditorialTheme.rule)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
                        .listRowBackground(EditorialTheme.surface)
                    }
                }
                if model.canLoadMore {
                    HStack {
                        Spacer()
                        Text("Load more")
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
            .contentMargins(.top, 0, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .background(EditorialTheme.paper)
        }
    }

    private var newspaperHeader: some View {
        VStack(spacing: 0) {
            PageHeader(title: "News", subtitle: "", isRefreshing: model.isRefreshing,
                       updatedAt: model.lastUpdatedAt, showsUpdateTime: true,
                       refresh: { Task { await model.refresh() } },
                       filterTitle: model.selectedSection == .latestComments ? nil : "\(impactFilterLabel) impact",
                       filterAction: {
                           withAnimation(.easeOut(duration: 0.16)) { isImpactFilterPresented = true }
                       })
            NewsSectionPicker(model: model)
        }
        .background(EditorialTheme.paper)
    }

    private var isEmpty: Bool {
        model.selectedSection == .latestComments
            ? model.currentComments.isEmpty
            : model.currentArticles.isEmpty
    }

    private var impactFilterOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()
                .onTapGesture { dismissImpactFilter() }

            NewsImpactFilterDialog(
                selectedImpact: model.impactFilter,
                onSelect: { option in
                    dismissImpactFilter()
                    Task { await model.setImpactFilter(option.impact) }
                },
                onDismiss: dismissImpactFilter
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
        .zIndex(1)
    }

    private func dismissImpactFilter() {
        withAnimation(.easeIn(duration: 0.12)) {
            isImpactFilterPresented = false
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

private enum NewsRoute: Hashable {
    case article(sourceID: String)
    case comment(articleID: String)
}

enum NewsImpactFilterOption: String, CaseIterable, Identifiable {
    case all = "ALL IMPACT"
    case high = "HIGH IMPACT"
    case medium = "MEDIUM IMPACT"
    case low = "LOW IMPACT"

    var id: Self { self }

    var impact: Impact? {
        switch self {
        case .all: nil
        case .high: .high
        case .medium: .medium
        case .low: .low
        }
    }

    func isSelected(filter: Impact?) -> Bool {
        impact == filter
    }
}

struct NewsImpactFilterDialog: View {
    let selectedImpact: Impact?
    let onSelect: (NewsImpactFilterOption) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Filter by impact")
                        .font(.headline)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close impact filter")
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)
            .padding(.vertical, 12)

            EditorialRule()

            ForEach(Array(NewsImpactFilterOption.allCases.enumerated()), id: \.element.id) { index, option in
                Button {
                    onSelect(option)
                } label: {
                    HStack(spacing: 12) {
                        Text(option.rawValue.capitalized)
                            .font(.body)
                        Spacer()
                        if option.isSelected(filter: selectedImpact) {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(EditorialTheme.accent)
                        }
                    }
                    .foregroundStyle(EditorialTheme.ink)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 54)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(option.isSelected(filter: selectedImpact) ? "Selected" : "")

                if index < NewsImpactFilterOption.allCases.count - 1 {
                    EditorialRule()
                        .padding(.horizontal, 18)
                }
            }
        }
        .padding(.bottom, 8)
        .background(EditorialTheme.surface)
        .foregroundStyle(EditorialTheme.ink)
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape, onDismiss)
    }
}
