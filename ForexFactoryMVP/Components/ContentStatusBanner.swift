import SwiftUI

struct ContentStatusBanner: View {
    let message: String?
    let staleSince: Date?

    var body: some View {
        if message != nil || staleSince != nil {
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(EditorialTheme.accent)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 2) {
                    if let message { Text(message) }
                    if let staleSince {
                        Text("Saved \(staleSince.formatted(date: .abbreviated, time: .shortened))")
                            .font(EditorialTheme.metadata)
                            .foregroundStyle(EditorialTheme.mutedInk)
                    }
                }
                Spacer(minLength: 0)
            }
            .font(.footnote)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(EditorialTheme.subtleSurface)
            .accessibilityElement(children: .combine)
        }
    }
}
