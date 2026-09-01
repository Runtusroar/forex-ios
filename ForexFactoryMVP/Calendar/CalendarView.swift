import SwiftUI

struct CalendarView: View {
    @Bindable var model: CalendarViewModel

    private var sections: [(date: Date, events: [CalendarEvent])] {
        Dictionary(grouping: model.events) { Calendar.current.startOfDay(for: $0.eventAt) }
            .map { (date: $0.key, events: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                if model.events.isEmpty, !model.isRefreshing {
                    ContentUnavailableView(
                        "No calendar events",
                        systemImage: "calendar",
                        description: Text("Add your server details in Settings, then pull to refresh.")
                    )
                } else {
                    List {
                        ForEach(sections, id: \.date) { section in
                            Section(section.date.formatted(.dateTime.weekday(.wide).month().day())) {
                                ForEach(section.events) { event in
                                    CalendarEventRow(event: event)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await model.refresh() }
                }
            }
            .navigationTitle("Economic Calendar")
            .toolbar {
                if model.isRefreshing {
                    ToolbarItem(placement: .topBarTrailing) { ProgressView() }
                }
            }
        }
    }
}

private struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(event.eventAt, style: .time)
                    .font(.subheadline.monospacedDigit())
                Text(event.currency)
                    .font(.subheadline.weight(.bold))
                ImpactBadge(impact: event.impact)
                Spacer()
            }
            BilingualText(english: event.titleEN, chinese: event.titleZH)
            HStack(spacing: 0) {
                ValueCell(label: "Actual", value: event.actual)
                ValueCell(label: "Forecast", value: event.forecast)
                ValueCell(label: "Previous", value: event.previous)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct ValueCell: View {
    let label: String
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value?.isEmpty == false ? value! : "—")
                .font(.caption.monospacedDigit().weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
