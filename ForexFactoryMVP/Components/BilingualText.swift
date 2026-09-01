import SwiftUI

struct BilingualText: View {
    let english: String
    let chinese: String?
    var englishFont: Font = .headline

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(english)
                .font(englishFont)
                .foregroundStyle(.primary)
            if let chinese, !chinese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(chinese)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
