import SwiftUI

struct RootTabView: View {
    let settings: AppSettings
    let calendarModel: CalendarViewModel
    let newsModel: NewsViewModel
    let contractsModel: ContractsViewModel

    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: RootTab

    init(settings: AppSettings, calendarModel: CalendarViewModel, newsModel: NewsViewModel,
         contractsModel: ContractsViewModel, initialTab: RootTab = .news) {
        self.settings = settings
        self.calendarModel = calendarModel
        self.newsModel = newsModel
        self.contractsModel = contractsModel
        _selection = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                EditorialTheme.paper.ignoresSafeArea()
                switch selection {
                case .calendar:
                    CalendarView(model: calendarModel)
                case .news:
                    NewsListView(model: newsModel)
                case .contracts:
                    ContractsView(model: contractsModel)
                case .settings:
                    SettingsView(settings: settings)
                }
            }
            editorialTabBar
        }
        .background(EditorialTheme.paper.ignoresSafeArea())
        .tint(EditorialTheme.accent)
        .onAppear { update(for: scenePhase) }
        .onChange(of: scenePhase) { _, newPhase in update(for: newPhase) }
        .onChange(of: selection) { _, _ in update(for: scenePhase) }
    }

    private var editorialTabBar: some View {
        VStack(spacing: 0) {
            EditorialRule()
            HStack(spacing: 0) {
                ForEach(RootTab.allCases) { tab in
                    Button {
                        selection = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 20, weight: .medium))
                            Text(tab.title)
                                .font(.caption2.weight(selection == tab ? .semibold : .medium))
                        }
                        .foregroundStyle(selection == tab ? EditorialTheme.accent : EditorialTheme.mutedInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.title)
                    .accessibilityAddTraits(selection == tab ? .isSelected : [])
                }
            }
        }
        .background(EditorialTheme.surface.ignoresSafeArea(edges: .bottom))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func update(for phase: ScenePhase) {
        calendarModel.deactivate()
        newsModel.deactivate()
        contractsModel.deactivate()

        switch RootTabRefreshPolicy.activeDataTab(
            selected: selection,
            appIsActive: phase == .active
        ) {
        case .calendar:
            calendarModel.activate()
        case .news:
            newsModel.activate()
        case .contracts:
            contractsModel.activate()
        case nil, .settings:
            break
        }
    }
}

enum RootTabRefreshPolicy {
    static func activeDataTab(
        selected: RootTab,
        appIsActive: Bool
    ) -> RootTab? {
        guard appIsActive, selected != .settings else { return nil }
        return selected
    }
}

enum RootTab: String, CaseIterable, Identifiable {
    case calendar
    case news
    case contracts
    case settings

    var id: Self { self }

    var title: String { rawValue.capitalized }

    var systemImage: String {
        switch self {
        case .calendar: "calendar"
        case .news: "newspaper"
        case .contracts: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }
}
