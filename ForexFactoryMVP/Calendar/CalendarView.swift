import SwiftUI

struct CalendarView: View {
    @Bindable var model: CalendarViewModel
    @State private var path = NavigationPath()

    private var sections: [(date: Date, events: [CalendarEvent])] {
        Dictionary(grouping: model.events) { EditorialDateFormatter.calendarDay($0.eventAt) }
            .map { (date: $0.key, events: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                if model.events.isEmpty, !model.isRefreshing {
                    ScrollView {
                        calendarHeader
                        ContentUnavailableView(
                            "No calendar events", systemImage: "calendar",
                            description: Text("Tap the update time to refresh, or check your connection in Settings.")
                        )
                        .padding(.top, EditorialSpacing.section)
                    }
                } else {
                    List {
                        calendarHeader
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        ForEach(sections, id: \.date) { section in
                            SectionBand(
                                title: EditorialDateFormatter.calendarDayLabel(section.date).capitalized,
                                detail: "\(section.events.count) \(section.events.count == 1 ? "event" : "events")"
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            ForEach(section.events) { event in
                                Button { path.append(event.sourceID) } label: {
                                    CalendarEventRow(event: event)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets(top: EditorialSpacing.row, leading: 20, bottom: EditorialSpacing.row, trailing: 20))
                                .listRowSeparatorTint(EditorialTheme.rule)
                                .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                                .alignmentGuide(.listRowSeparatorTrailing) { $0.width }
                            }
                        }
                        .listRowBackground(EditorialTheme.surface)
                    }
                    .listStyle(.plain)
                    .contentMargins(.top, 0, for: .scrollContent)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(EditorialTheme.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { sourceID in
                if let event = model.events.first(where: { $0.sourceID == sourceID }) {
                    CalendarDetailView(event: event, model: model)
                } else {
                    ContentUnavailableView("Event unavailable", systemImage: "calendar.badge.exclamationmark")
                }
            }
        }
    }

    private var calendarHeader: some View {
        PageHeader(title: "Calendar", subtitle: "Economic calendar · UTC+8", isRefreshing: model.isRefreshing, updatedAt: model.lastUpdatedAt, showsUpdateTime: true, refresh: { Task { await model.refresh() } })
    }
}

struct CalendarEventRow: View {
    let event: CalendarEvent
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialSpacing.related) {
            metadataLayout {
                Text(EditorialDateFormatter.calendarTime(event))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(EditorialTheme.mutedInk)
                Text(event.currency)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EditorialTheme.ink)
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                ImpactBadge(impact: event.impact)
            }
            HStack(alignment: .top, spacing: 12) {
                ContentText(english: event.titleEN, font: .body.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(EditorialTheme.mutedInk)
                    .padding(.top, 4)
                    .accessibilityHidden(true)
            }
            valueLayout {
                ValueCell(label: "Actual", value: event.actual, emphasized: true)
                ValueCell(label: "Forecast", value: event.forecast)
                ValueCell(label: "Previous", value: event.previous)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var metadataLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
    }

    private var valueLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
    }
}

private struct ValueCell: View {
    let label: String
    let value: String?
    var emphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialSpacing.inline) {
            Text(label).font(.caption).foregroundStyle(EditorialTheme.mutedInk)
            Text(value?.isEmpty == false ? value! : "—")
                .font(.body.monospacedDigit().weight(emphasized ? .semibold : .regular))
                .foregroundStyle(emphasized ? EditorialTheme.ink : EditorialTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(value?.isEmpty == false ? value! : "Not available")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
