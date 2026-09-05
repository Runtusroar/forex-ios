import SwiftUI

struct NewsSectionPicker: View {
    @Bindable var model: NewsViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: EditorialSpacing.section) {
                ForEach(model.sections) { section in
                    CategoryTab(title: section.name.en ?? section.id.rawValue, isSelected: model.selectedSection == section.id) {
                        Task { await model.select(section.id) }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(EditorialTheme.paper)
    }
}
