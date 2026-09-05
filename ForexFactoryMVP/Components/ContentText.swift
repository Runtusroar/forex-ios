import SwiftUI

/// English content presentation; translations remain available in API models.
struct ContentText: View {
    let english: String
    var font: Font = .body

    var body: some View {
        Text(english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Content unavailable" : english)
            .font(font)
            .foregroundStyle(EditorialTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}
