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
                        Button {
                            path.append(.comment(articleID: comment.articleID))
                        } label: {
                            NewsCommentCard(comment: comment)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowBackground(EditorialTheme.paper)
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
            VStack(spacing: 10) {
                EditorialMasthead(section: "News")
                HStack {
                    Spacer()
                    Text("TIMEZONE · \(EditorialDateFormatter.utcPlusEightLabel)")
                        .font(EditorialTheme.smallCaps)
                        .tracking(0.8)
                        .foregroundStyle(EditorialTheme.accent)
                }
            }
                .padding(.horizontal)
                .padding(.top, 8)
            HStack {
                impactFilterButton
                Spacer()
                if model.isRefreshing { ProgressView() }
            }
            .padding(.horizontal)
            NewsSectionPicker(model: model)
        }
        .background(EditorialTheme.paper)
    }

    private var isEmpty: Bool {
        model.selectedSection == .latestComments
            ? model.currentComments.isEmpty
            : model.currentArticles.isEmpty
    }

    @ViewBuilder
    private var impactFilterButton: some View {
        if model.selectedSection != .latestComments {
            Button {
                withAnimation(.easeOut(duration: 0.16)) {
                    isImpactFilterPresented = true
                }
            } label: {
                HStack(spacing: 6) {
                    Text("\(impactFilterLabel) IMPACT")
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .font(EditorialTheme.smallCaps)
                .tracking(0.7)
                .foregroundStyle(EditorialTheme.ink)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filter by impact")
            .accessibilityValue(impactFilterLabel)
        }
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

private struct NewsImpactFilterDialog: View {
    let selectedImpact: Impact?
    let onSelect: (NewsImpactFilterOption) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NEWS DESK")
                        .font(EditorialTheme.smallCaps)
                        .tracking(1.1)
                        .foregroundStyle(EditorialTheme.accent)
                    Text("Filter by impact")
                        .font(EditorialTheme.headline(.title2))
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

            EditorialRule(weight: .double)

            ForEach(Array(NewsImpactFilterOption.allCases.enumerated()), id: \.element.id) { index, option in
                Button {
                    onSelect(option)
                } label: {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(option.isSelected(filter: selectedImpact) ? EditorialTheme.accent : .clear)
                            .frame(width: 3, height: 24)
                        Text(option.rawValue)
                            .font(EditorialTheme.metadata.weight(.bold))
                            .tracking(0.7)
                        Spacer()
                        if option.isSelected(filter: selectedImpact) {
                            Text("SELECTED")
                                .font(EditorialTheme.smallCaps)
                                .tracking(0.6)
                                .foregroundStyle(EditorialTheme.accent)
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
        .background(EditorialTheme.paper)
        .background {
            Rectangle()
                .fill(Color.black.opacity(0.35))
                .offset(x: 6, y: 6)
        }
        .overlay {
            Rectangle()
                .stroke(EditorialTheme.ink, lineWidth: 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape, onDismiss)
    }
}
