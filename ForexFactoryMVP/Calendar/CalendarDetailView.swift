import SwiftUI

struct CalendarDetailView: View {
    let event: CalendarEvent
    let model: CalendarViewModel

    @State private var detail: CalendarDetail?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            EditorialTheme.paper.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: EditorialSpacing.section) {
                    header
                    valueStrip
                    if let detail {
                        specs(detail)
                        history(detail.history)
                        relatedStories(detail.relatedStories)
                        links(detail)
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
                .padding(.horizontal, 20)
                .padding(.bottom, EditorialSpacing.section)
            }
        }
        .navigationTitle("Event")
        .toolbar(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(EditorialTheme.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task(id: event.sourceID) { await load() }
    }

    private var displayDetail: CalendarDetail? { detail }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            metadataLayout {
                Text((displayDetail?.currency ?? event.currency).uppercased())
                    .font(EditorialTheme.smallCaps)
                    .tracking(0.8)
                    .foregroundStyle(EditorialTheme.ink)
                if let currencyName = displayDetail?.currencyName, !currencyName.isEmpty {
                    Text(currencyName.uppercased())
                        .font(EditorialTheme.smallCaps)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                ImpactBadge(impact: displayDetail?.impact ?? event.impact)
            }
            ContentText(
                english: displayDetail?.titleEN ?? event.titleEN,
                font: .title2.weight(.semibold)
            )
            Text("\(EditorialDateFormatter.calendarDayLabel(event.eventAt).capitalized) · \(EditorialDateFormatter.calendarTime(event)) · UTC+8")
                .font(EditorialTheme.metadata.monospacedDigit())
                .foregroundStyle(EditorialTheme.mutedInk)
            LastUpdatedText(date: detail?.updatedAt ?? event.updatedAt)
        }
        .padding(.top, EditorialSpacing.content)
    }

    private var valueStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            valueLayout {
                DetailValueCell(
                    label: "Actual",
                    value: displayDetail?.actual ?? event.actual,
                    state: displayDetail?.actualState,
                    emphasized: true
                )
                DetailValueCell(label: "Forecast", value: displayDetail?.forecast ?? event.forecast)
                DetailValueCell(
                    label: "Previous",
                    value: displayDetail?.previous ?? event.previous,
                    state: displayDetail?.previousState
                )
            }
            if let revised = displayDetail?.previousRevisedFrom {
                Text("Revised from \(revised)")
                    .font(EditorialTheme.smallCaps)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
        }
        .padding(16)
        .background(EditorialTheme.subtleSurface)
    }

    private func specs(_ detail: CalendarDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("About this release")
            infoRow("Source", detail.sourceName)
            infoRow("Measures", detail.measures)
            infoRow("Usual Effect", detail.usualEffect)
            infoRow("Frequency", detail.frequency)
            infoRow("Next Release", detail.nextReleaseText)
            infoRow("FF Notes", detail.ffNotes)
            infoRow("Why Traders Care", detail.whyTradersCare)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        Text(row.releaseDateText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(EditorialTheme.ink)
                        valueLayout {
                            DetailValueCell(label: "Actual", value: row.actual, state: row.actualState, emphasized: true)
                            DetailValueCell(label: "Forecast", value: row.forecast)
                            DetailValueCell(label: "Previous", value: row.previous, state: row.previousState)
                        }
                        if let revised = row.previousRevisedFrom {
                            Text("Revised from \(revised)")
                                .font(EditorialTheme.smallCaps)
                                .foregroundStyle(EditorialTheme.mutedInk)
                        }
                    }
                    .padding(16)
                    .background(EditorialTheme.subtleSurface)
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
                Link("View event on Forex Factory", destination: ffURL).frame(minHeight: 44, alignment: .leading)
            }
            if let sourceURL = detail.sourceURL {
                Link("View source", destination: sourceURL).frame(minHeight: 44, alignment: .leading)
            }
            if let latestReleaseURL = detail.latestReleaseURL {
                Link("View latest release", destination: latestReleaseURL).frame(minHeight: 44, alignment: .leading)
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(EditorialTheme.accent)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.capitalized)
            .font(.headline)
            .foregroundStyle(EditorialTheme.ink)
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(EditorialTheme.mutedInk)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(EditorialTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var valueLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
    }

    private var metadataLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
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
    var emphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(EditorialTheme.mutedInk)
            Text(value?.isEmpty == false ? value! : "—")
                .font(.body.monospacedDigit().weight(emphasized ? .semibold : .regular))
                .foregroundStyle(valueColor)
                .fixedSize(horizontal: false, vertical: true)
            if let state, state != .unknown {
                Text(state.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var valueColor: Color {
        switch state {
        case .better: EditorialTheme.positive
        case .worse: EditorialTheme.negative
        case .unknown, .none: EditorialTheme.ink
        }
    }
}
