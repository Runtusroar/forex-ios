import SwiftUI
import UIKit

struct NewsMediaView: View {
    let media: NewsMedia
    let model: NewsViewModel

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else if failed {
                    ContentUnavailableView("Image unavailable", systemImage: "photo.badge.exclamationmark")
                        .frame(minHeight: 120)
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 120)
                }
            }
            .frame(maxWidth: .infinity)
            .background(EditorialTheme.subtleSurface)
            .overlay {
                Rectangle()
                    .stroke(EditorialTheme.rule.opacity(0.35), lineWidth: 0.5)
            }
            if let caption = media.caption, !caption.isEmpty {
                Text(caption.uppercased())
                    .font(EditorialTheme.smallCaps)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
        }
        .task(id: media.url) { await load() }
    }

    private func load() async {
        guard image == nil, !failed, media.downloadState == .complete, let path = media.url else {
            failed = media.downloadState == .failed || media.url == nil
            return
        }
        do {
            let data = try await model.mediaData(path: path)
            guard let loadedImage = UIImage(data: data) else {
                failed = true
                return
            }
            image = loadedImage
        } catch {
            failed = true
        }
    }
}
