import SwiftUI

struct NewsSectionPicker: View {
    @Bindable var model: NewsViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 28) {
                ForEach(model.sections) { section in
                    Button {
                        Task { await model.select(section.id) }
                    } label: {
                        VStack(spacing: 6) {
                            Text(section.name.en ?? section.id.rawValue)
                                .font(.system(.subheadline, design: .default, weight: .semibold))
                            if let chinese = section.name.zhHans, !chinese.isEmpty {
                                Text(chinese)
                                    .font(.caption2)
                                    .foregroundStyle(EditorialTheme.mutedInk)
                            }
                            Rectangle()
                                .fill(
                                    model.selectedSection == section.id
                                        ? EditorialTheme.accent
                                        : Color.clear
                                )
                                .frame(height: 3)
                        }
                        .foregroundStyle(
                            model.selectedSection == section.id
                                ? EditorialTheme.accent
                                : EditorialTheme.ink
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityValue(model.selectedSection == section.id ? "Selected" : "")
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(EditorialTheme.paper)
        .overlay(alignment: .bottom) {
            EditorialRule()
        }
    }
}
