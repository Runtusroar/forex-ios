import SwiftUI

struct ContentStatusBanner: View {
    let message: String?
    let staleSince: Date?

    var body: some View {
        if message != nil || staleSince != nil {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    if let message { Text(message) }
                    if let staleSince {
                        Text("Cached data from \(EditorialDateFormatter.publicationDate(staleSince)) \(EditorialDateFormatter.newsTime(staleSince)) \(EditorialDateFormatter.utcPlusEightLabel)")
                            .font(EditorialTheme.metadata)
                            .foregroundStyle(EditorialTheme.mutedInk)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, 13)
            .font(.footnote)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(EditorialTheme.subtleSurface)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(EditorialTheme.accent)
                    .frame(width: 3)
                    .padding(.leading, 16)
                    .padding(.vertical, 10)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
