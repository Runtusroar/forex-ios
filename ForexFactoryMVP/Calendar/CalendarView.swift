import SwiftUI

struct CalendarView: View {
    @Bindable var model: CalendarViewModel

    private var sections: [(date: Date, events: [CalendarEvent])] {
        Dictionary(grouping: model.events) { EditorialDateFormatter.calendarDay($0.eventAt) }
            .map { (date: $0.key, events: $0.value) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EditorialTheme.paper.ignoresSafeArea()
                VStack(spacing: 0) {
                    ContentStatusBanner(message: model.errorMessage, staleSince: model.staleSince)
                    if model.events.isEmpty, !model.isRefreshing {
                        ScrollView {
                            VStack(spacing: 40) {
                                calendarHeader
                                ContentUnavailableView(
                                    "No calendar events",
                                    systemImage: "calendar",
                                    description: Text("Add your server details in Settings, then pull to refresh.")
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        .refreshable { await model.refresh() }
                    } else {
                        List {
                            calendarHeader
                                .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 12, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(EditorialTheme.paper)

                        ForEach(sections, id: \.date) { section in
                            Section {
                                ForEach(section.events) { event in
                                    NavigationLink {
                                        CalendarDetailView(event: event, model: model)
                                    } label: {
                                        CalendarEventRow(event: event)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(EditorialTheme.paper)
                                }
                            } header: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(EditorialDateFormatter.calendarDayLabel(section.date))
                                        .font(EditorialTheme.smallCaps)
                                        .tracking(1.2)
                                        .foregroundStyle(EditorialTheme.accent)
                                    EditorialRule(weight: .strong)
                                }
                                .padding(.top, 18)
                                .textCase(nil)
                            }
                        }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { await model.refresh() }
                    }
                }
            }
            .toolbarBackground(EditorialTheme.paper, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                if model.isRefreshing {
                    ToolbarItem(placement: .topBarTrailing) { ProgressView() }
                }
            }
        }
    }

    private var calendarHeader: some View {
        VStack(spacing: 10) {
            EditorialMasthead(section: "Calendar")
            HStack {
                Spacer()
                Text("TIMEZONE · \(EditorialDateFormatter.utcPlusEightLabel)")
                    .font(EditorialTheme.smallCaps)
                    .tracking(0.8)
                    .foregroundStyle(EditorialTheme.accent)
            }
        }
    }
}

private struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(EditorialDateFormatter.calendarTime(event))
                    .font(EditorialTheme.metadata.monospacedDigit())
                Text(event.currency)
                    .font(EditorialTheme.metadata.weight(.bold))
                ImpactBadge(impact: event.impact)
                Spacer()
            }
            BilingualText(english: event.titleEN, chinese: event.titleZH, role: .sectionHeadline)
            EditorialRule()
            HStack(spacing: 0) {
                ValueCell(label: "Actual", value: event.actual)
                EditorialValueDivider()
                ValueCell(label: "Forecast", value: event.forecast)
                EditorialValueDivider()
                ValueCell(label: "Previous", value: event.previous)
            }
            EditorialRule()
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

private struct ValueCell: View {
    let label: String
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(EditorialTheme.smallCaps)
                .textCase(.uppercase)
                .foregroundStyle(EditorialTheme.mutedInk)
            Text(value?.isEmpty == false ? value! : "—")
                .font(EditorialTheme.metadata.monospacedDigit().weight(.semibold))
                .foregroundStyle(EditorialTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EditorialValueDivider: View {
    var body: some View {
        Rectangle()
            .fill(EditorialTheme.rule)
            .frame(width: 1)
            .padding(.vertical, 1)
            .padding(.horizontal, 10)
    }
}
