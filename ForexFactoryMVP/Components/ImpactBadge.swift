import SwiftUI

struct ImpactBadge: View {
    let impact: Impact

    private var label: String {
        switch impact {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .holiday: "Holiday"
        case .unknown: "Unknown"
        }
    }

    private var color: Color {
        switch impact {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        case .holiday: .purple
        case .unknown: .gray
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.13), in: Capsule())
            .accessibilityLabel("\(label) impact")
    }
}
