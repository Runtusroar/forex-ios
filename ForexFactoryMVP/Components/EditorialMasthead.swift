import SwiftUI

enum EditorialRuleWeight {
    case hairline
    case strong
    case double
}

struct EditorialRule: View {
    var weight: EditorialRuleWeight = .hairline

    var body: some View {
        switch weight {
        case .hairline:
            Rectangle()
                .fill(EditorialTheme.rule)
                .frame(height: 0.5)
        case .strong:
            Rectangle()
                .fill(EditorialTheme.ink)
                .frame(height: 2)
        case .double:
            VStack(spacing: 3) {
                Rectangle()
                    .fill(EditorialTheme.ink)
                    .frame(height: 3)
                Rectangle()
                    .fill(EditorialTheme.ink)
                    .frame(height: 1)
            }
        }
    }
}

struct EditorialMasthead: View {
    let section: String
    var kicker = "FOREX FACTORY · PRIVATE EDITION"
    var date: Date? = Date()

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 58

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(kicker)
                    .font(EditorialTheme.smallCaps)
                    .tracking(0.7)
                Spacer(minLength: 8)
                if let date {
                    Text(EditorialDateFormatter.publicationDate(date))
                        .font(EditorialTheme.smallCaps)
                        .foregroundStyle(EditorialTheme.accent)
                }
            }
            Text(section)
                .font(.system(size: titleSize, weight: .regular, design: .serif))
                .tracking(-1.2)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
            EditorialRule(weight: .double)
        }
        .foregroundStyle(EditorialTheme.ink)
        .accessibilityElement(children: .combine)
    }
}
