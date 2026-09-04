import SwiftUI

@main
struct ForexFactoryMVPApp: App {
    @State private var settings: AppSettings
    @State private var calendarModel: CalendarViewModel
    @State private var newsModel: NewsViewModel

    init() {
        let settings = AppSettings()
        let cache = ResponseCache()
        _settings = State(initialValue: settings)
        _calendarModel = State(initialValue: CalendarViewModel(settings: settings, cache: cache))
        _newsModel = State(initialValue: NewsViewModel(settings: settings, cache: cache))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                settings: settings,
                calendarModel: calendarModel,
                newsModel: newsModel
            )
            .background(EditorialTheme.paper)
            .foregroundStyle(EditorialTheme.ink)
        }
    }
}
