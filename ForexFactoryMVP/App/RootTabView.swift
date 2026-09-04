import SwiftUI

struct RootTabView: View {
    let settings: AppSettings
    let calendarModel: CalendarViewModel
    let newsModel: NewsViewModel
    let contractsModel: ContractsViewModel

    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: RootTab = .news

    var body: some View {
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
        .safeAreaInset(edge: .bottom, spacing: 0) { editorialTabBar }
        .tint(EditorialTheme.accent)
        .onAppear { update(for: scenePhase) }
        .onChange(of: scenePhase) { _, newPhase in update(for: newPhase) }
    }

    private var editorialTabBar: some View {
        VStack(spacing: 0) {
            EditorialRule(weight: .strong)
            HStack(spacing: 0) {
                ForEach(RootTab.allCases) { tab in
                    Button {
                        selection = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                            Text(tab.title.uppercased())
                                .font(EditorialTheme.smallCaps)
                                .tracking(0.6)
                        }
                        .foregroundStyle(selection == tab ? EditorialTheme.accent : EditorialTheme.ink)
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
        .background(EditorialTheme.paper.ignoresSafeArea())
    }

    private func update(for phase: ScenePhase) {
        if phase == .active {
            calendarModel.activate()
            newsModel.activate()
            contractsModel.activate()
        } else {
            calendarModel.deactivate()
            newsModel.deactivate()
            contractsModel.deactivate()
        }
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
