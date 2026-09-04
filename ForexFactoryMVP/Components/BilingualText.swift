import SwiftUI

enum BilingualTextRole {
    case headline
    case sectionHeadline
    case body
}

struct BilingualText: View {
    let english: String
    let chinese: String?
    var role: BilingualTextRole = .headline
    var englishFont: Font?

    private var resolvedEnglishFont: Font {
        if let englishFont { return englishFont }
        switch role {
        case .headline:
            return EditorialTheme.headline(.headline)
        case .sectionHeadline:
            return EditorialTheme.headline(.title3, weight: .semibold)
        case .body:
            return .body
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(english)
                .font(resolvedEnglishFont)
                .foregroundStyle(EditorialTheme.ink)
                .lineSpacing(role == .body ? 3 : 1)
            if let chinese, !chinese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(chinese)
                    .font(.subheadline)
                    .foregroundStyle(EditorialTheme.mutedInk)
                    .lineSpacing(2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
