import SwiftUI

struct PageHeader: View {
    let title: String
    let subtitle: String
    var isRefreshing = false
    var updatedAt: Date? = nil
    var showsUpdateTime = false
    var isDelayed = false
    var refresh: (() -> Void)? = nil
    var date: Date? = Date()
    var filterTitle: String? = nil
    var filterAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialSpacing.inline) {
            EditorialMasthead(section: title, date: date, filterTitle: filterTitle, filterAction: filterAction)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(EditorialTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if showsUpdateTime {
                if let refresh {
                    Button(action: refresh) {
                        LastUpdatedText(date: updatedAt, isDelayed: isDelayed)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isRefreshing)
                    .accessibilityHint("Refresh this page")
                } else {
                    LastUpdatedText(date: updatedAt, isDelayed: isDelayed)
                }
            }
        }
        .padding(.horizontal, EditorialSpacing.page)
        .padding(.top, EditorialSpacing.content)
        .padding(.bottom, EditorialSpacing.related)
        .background(EditorialTheme.paper)
    }
}

struct SectionBand: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
            if let detail {
                Text(detail).font(.caption.monospacedDigit())
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
        }
        .foregroundStyle(EditorialTheme.ink)
        .padding(.horizontal, EditorialSpacing.page)
        .padding(.vertical, EditorialSpacing.related)
        .background(EditorialTheme.subtleSurface)
        .accessibilityAddTraits(.isHeader)
    }
}

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? EditorialTheme.accent : EditorialTheme.mutedInk)
                .padding(.horizontal, 2)
                .frame(minWidth: 44, minHeight: 44)
                .padding(.bottom, 2)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(isSelected ? EditorialTheme.accent : .clear).frame(height: 2)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct FlatActionStyle: ButtonStyle {
    var primary = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(primary ? EditorialTheme.onAccent : EditorialTheme.accent)
            .background(primary ? EditorialTheme.accent : EditorialTheme.subtleSurface,
                        in: RoundedRectangle(cornerRadius: 3))
            .opacity(!isEnabled ? 0.5 : configuration.isPressed ? 0.75 : 1)
    }
}

struct LastUpdatedText: View {
    let date: Date?
    var isDelayed = false

    nonisolated static func label(date: Date?, isDelayed: Bool) -> String {
        let timestamp = date.map(EditorialDateFormatter.timestamp) ?? "— · UTC+8"
        return "Last updated \(timestamp)" + (isDelayed ? " · Delayed" : "")
    }

    var body: some View {
        Text(Self.label(date: date, isDelayed: isDelayed))
            .font(.caption.monospacedDigit())
            .foregroundStyle(isDelayed ? EditorialTheme.accent : EditorialTheme.mutedInk)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("last-updated")
    }
}
