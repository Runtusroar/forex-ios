import SwiftUI

struct ContentStatusBanner: View {
    let message: String?
    let staleSince: Date?

    var body: some View {
        if message != nil || staleSince != nil {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    if let message { Text(message) }
                    if let staleSince {
                        Text("Saved \(staleSince.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .font(.footnote)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.orange.opacity(0.08))
            .accessibilityElement(children: .combine)
        }
    }
}
