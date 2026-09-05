import SwiftUI

enum EditorialRuleWeight {
    case hairline
    case strong
    case double
}

struct EditorialRule: View {
    var weight: EditorialRuleWeight = .hairline

    var body: some View {
        Rectangle()
            .fill(EditorialTheme.rule)
            .frame(height: weight == .hairline ? 0.5 : 1)
            .accessibilityHidden(true)
    }
}

struct EditorialMasthead: View {
    let section: String
    var date: Date? = Date()
    var filterTitle: String? = nil
    var filterAction: (() -> Void)? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: EditorialSpacing.inline) {
            let headingLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: EditorialSpacing.inline))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: EditorialSpacing.related))
            headingLayout {
                Text(section)
                    .font(.title.weight(.bold))
                    .tracking(-0.4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let filterTitle, let filterAction {
                    Button(action: filterAction) {
                        HStack(spacing: 6) {
                            Text(filterTitle)
                            Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(EditorialTheme.accent)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .background(EditorialTheme.subtleSurface)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filter by impact")
                    .accessibilityValue(filterTitle)
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
                if let date {
                    Text(EditorialDateFormatter.publicationDate(date))
                        .font(EditorialTheme.smallCaps)
                        .foregroundStyle(EditorialTheme.mutedInk)
                        .fixedSize()
                        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil, alignment: .trailing)
                }
            }

        }
        .foregroundStyle(EditorialTheme.ink)
        .accessibilityElement(children: .contain)
    }
}
