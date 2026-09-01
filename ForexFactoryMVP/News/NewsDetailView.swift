import SwiftUI

struct NewsDetailView: View {
    let item: NewsItem
    let model: NewsViewModel

    @State private var detail: NewsItem?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var displayedItem: NewsItem { detail ?? item }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(displayedItem.source ?? "Forex Factory")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                BilingualText(
                    english: displayedItem.titleEN,
                    chinese: displayedItem.titleZH,
                    englishFont: .title2.bold()
                )
                if let imageURL = displayedItem.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                if let body = displayedItem.bodyEN, !body.isEmpty {
                    Text(body).font(.body)
                }
                if let body = displayedItem.bodyZH, !body.isEmpty {
                    Divider()
                    Text(body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                if isLoading { ProgressView("Loading full story…") }
                if let errorMessage {
                    ContentUnavailableView {
                        Label("Unable to load full story", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") { Task { await load() } }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("News Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            detail = try await model.detail(id: item.sourceID)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Please try again."
        }
    }
}
