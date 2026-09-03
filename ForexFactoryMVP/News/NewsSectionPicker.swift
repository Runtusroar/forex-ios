import SwiftUI

struct NewsSectionPicker: View {
    @Bindable var model: NewsViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.sections) { section in
                    Button {
                        Task { await model.select(section.id) }
                    } label: {
                        VStack(spacing: 1) {
                            Text(section.name.en ?? section.id.rawValue)
                                .font(.subheadline.weight(.semibold))
                            if let chinese = section.name.zhHans, !chinese.isEmpty {
                                Text(chinese).font(.caption2)
                            }
                        }
                        .foregroundStyle(model.selectedSection == section.id ? .white : .primary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .background(
                            model.selectedSection == section.id ? Color.accentColor : Color.secondary.opacity(0.12),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(model.selectedSection == section.id ? "Selected" : "")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}
