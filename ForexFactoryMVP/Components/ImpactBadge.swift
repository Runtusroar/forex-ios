import SwiftUI

struct ImpactBadge: View {
    let impact: Impact

    var body: some View {
        HStack(spacing: 5) {
            Rectangle()
                .fill(impact.editorialColor)
                .frame(width: 7, height: 7)
            Text(impact.editorialLabel)
                .font(EditorialTheme.smallCaps)
                .tracking(0.4)
                .foregroundStyle(EditorialTheme.mutedInk)
        }
        .accessibilityLabel("\(impact.editorialLabel.capitalized) impact")
    }
}
