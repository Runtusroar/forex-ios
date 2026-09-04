import SwiftUI

struct CalendarDetailView: View {
    let event: CalendarEvent
    let model: CalendarViewModel

    @State private var detail: CalendarDetail?
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            EditorialTheme.paper.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    header
                    valueStrip
                    if let detail {
                        specs(detail)
                        history(detail.history)
                        relatedStories(detail.relatedStories)
                        links(detail)
                    }
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("LOADING FOREX FACTORY DETAIL...")
                                .font(EditorialTheme.smallCaps)
                        }
                    }
                    if let errorMessage {
                        ContentUnavailableView {
                            Label("Unable to load detail", systemImage: "wifi.exclamationmark")
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Retry") { Task { await load() } }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("EVENT")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(EditorialTheme.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: event.sourceID) { await load() }
    }

    private var displayDetail: CalendarDetail? { detail }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text((displayDetail?.currency ?? event.currency).uppercased())
                    .font(EditorialTheme.smallCaps)
                    .tracking(0.8)
                    .foregroundStyle(EditorialTheme.accent)
                if let currencyName = displayDetail?.currencyName, !currencyName.isEmpty {
                    Text(currencyName.uppercased())
                        .font(EditorialTheme.smallCaps)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
                Spacer()
                ImpactBadge(impact: displayDetail?.impact ?? event.impact)
            }
            Text(displayDetail?.titleEN ?? event.titleEN)
                .font(EditorialTheme.headline(.title, weight: .bold))
                .foregroundStyle(EditorialTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(EditorialDateFormatter.calendarTime(event))
                .font(EditorialTheme.metadata.monospacedDigit())
                .foregroundStyle(EditorialTheme.mutedInk)
            EditorialRule(weight: .strong)
        }
        .padding(.top, 12)
    }

    private var valueStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                DetailValueCell(
                    label: "Actual",
                    value: displayDetail?.actual ?? event.actual,
                    state: displayDetail?.actualState
                )
                DetailValueDivider()
                DetailValueCell(label: "Forecast", value: displayDetail?.forecast ?? event.forecast)
                DetailValueDivider()
                DetailValueCell(
                    label: "Previous",
                    value: displayDetail?.previous ?? event.previous,
                    state: displayDetail?.previousState
                )
            }
            if let revised = displayDetail?.previousRevisedFrom {
                Text("REVISED FROM \(revised)")
                    .font(EditorialTheme.smallCaps)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
            EditorialRule()
        }
    }

    private func specs(_ detail: CalendarDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SPECS")
            infoRow("Source", detail.sourceName)
            infoRow("Measures", detail.measures)
            infoRow("Usual Effect", detail.usualEffect)
            infoRow("Frequency", detail.frequency)
            infoRow("Next Release", detail.nextReleaseText)
            infoRow("FF Notes", detail.ffNotes)
            infoRow("Why Traders Care", detail.whyTradersCare)
        }
    }

    private func history(_ rows: [CalendarHistoryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("HISTORY")
            if rows.isEmpty {
                Text("No history available.")
                    .font(.footnote)
                    .foregroundStyle(EditorialTheme.mutedInk)
            } else {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.releaseDateText.uppercased())
                            .font(EditorialTheme.smallCaps)
                            .foregroundStyle(EditorialTheme.accent)
                        HStack(spacing: 0) {
                            DetailValueCell(label: "Actual", value: row.actual, state: row.actualState)
                            DetailValueDivider()
                            DetailValueCell(label: "Forecast", value: row.forecast)
                            DetailValueDivider()
                            DetailValueCell(label: "Previous", value: row.previous, state: row.previousState)
                        }
                        if let revised = row.previousRevisedFrom {
                            Text("REVISED FROM \(revised)")
                                .font(EditorialTheme.smallCaps)
                                .foregroundStyle(EditorialTheme.mutedInk)
                        }
                    }
                    EditorialRule()
                }
            }
        }
    }

    private func relatedStories(_ stories: [CalendarRelatedStory]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("RELATED STORIES")
            if stories.isEmpty {
                Text("No related stories available.")
                    .font(.footnote)
                    .foregroundStyle(EditorialTheme.mutedInk)
            } else {
                ForEach(stories) { story in
                    VStack(alignment: .leading, spacing: 6) {
                        Link(story.titleEN, destination: story.ffURL)
                            .font(EditorialTheme.headline(.headline, weight: .semibold))
                            .foregroundStyle(EditorialTheme.ink)
                        HStack(spacing: 6) {
                            if let sourceName = story.sourceName {
                                Text(sourceName.uppercased())
                            }
                            if let published = story.publishedAtSourceText {
                                Text(published.uppercased())
                            }
                        }
                        .font(EditorialTheme.smallCaps)
                        .foregroundStyle(EditorialTheme.mutedInk)
                        if let preview = story.preview, !preview.isEmpty {
                            Text(preview)
                                .font(.footnote)
                                .foregroundStyle(EditorialTheme.mutedInk)
                        }
                    }
                    EditorialRule()
                }
            }
        }
    }

    private func links(_ detail: CalendarDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let ffURL = detail.ffURL {
                Link("OPEN FULL EVENT ON FOREX FACTORY", destination: ffURL)
            }
            if let sourceURL = detail.sourceURL {
                Link("OPEN SOURCE", destination: sourceURL)
            }
            if let latestReleaseURL = detail.latestReleaseURL {
                Link("OPEN LATEST RELEASE", destination: latestReleaseURL)
            }
        }
        .font(EditorialTheme.smallCaps)
        .tracking(0.5)
        .foregroundStyle(EditorialTheme.accent)
        .underline()
    }

    private func sectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            EditorialRule(weight: .double)
            Text(title)
                .font(EditorialTheme.smallCaps)
                .tracking(1.2)
                .foregroundStyle(EditorialTheme.accent)
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .font(EditorialTheme.smallCaps)
                    .foregroundStyle(EditorialTheme.mutedInk)
                Text(value)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(EditorialTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            detail = try await model.detail(for: event)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Please try again."
        }
    }
}

private struct DetailValueCell: View {
    let label: String
    let value: String?
    var state: CalendarValueState?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(EditorialTheme.smallCaps)
                .foregroundStyle(EditorialTheme.mutedInk)
            Text(value?.isEmpty == false ? value! : "-")
                .font(EditorialTheme.metadata.monospacedDigit().weight(.semibold))
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var valueColor: Color {
        switch state {
        case .better: Color(red: 0.08, green: 0.36, blue: 0.27)
        case .worse: EditorialTheme.accent
        case .unknown, .none: EditorialTheme.ink
        }
    }
}

private struct DetailValueDivider: View {
    var body: some View {
        Rectangle()
            .fill(EditorialTheme.rule)
            .frame(width: 1)
            .padding(.vertical, 1)
            .padding(.horizontal, 10)
    }
}
