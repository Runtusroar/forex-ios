import SwiftUI

struct RootTabView: View {
    let settings: AppSettings
    let calendarModel: CalendarViewModel
    let newsModel: NewsViewModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            CalendarView(model: calendarModel)
                .tabItem { Label("Calendar", systemImage: "calendar") }
            NewsListView(model: newsModel)
                .tabItem { Label("News", systemImage: "newspaper") }
            SettingsView(settings: settings)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .onAppear { update(for: scenePhase) }
        .onChange(of: scenePhase) { _, newPhase in update(for: newPhase) }
    }

    private func update(for phase: ScenePhase) {
        if phase == .active {
            calendarModel.activate()
            newsModel.activate()
        } else {
            calendarModel.deactivate()
            newsModel.deactivate()
        }
    }
}
