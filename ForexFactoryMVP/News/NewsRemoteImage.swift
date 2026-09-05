import SwiftUI
import UIKit

/// Public thumbnails never receive backend authentication headers.
struct NewsRemoteImage: View {
    let url: URL
    var fillsFrame = false
    var placeholderHeight: CGFloat = 120
    @State private var image: UIImage?
    @State private var loadedURL: URL?
    @State private var failed = false

    var body: some View {
        Group {
            if let image, loadedURL == url {
                if fillsFrame { Image(uiImage: image).resizable().scaledToFill() }
                else { Image(uiImage: image).resizable().scaledToFit() }
            } else {
                EditorialTheme.subtleSurface
                    .frame(minHeight: placeholderHeight)
                    .overlay {
                        if failed { Image(systemName: "photo").foregroundStyle(EditorialTheme.mutedInk) }
                    }
            }
        }
        .task(id: url) {
            guard loadedURL != url || image == nil else { return }
            image = nil
            failed = false
            do {
                guard url.scheme == "https" else { throw APIError.invalidConfiguration }
                var request = URLRequest(url: url, timeoutInterval: 20)
                request.setValue("image/*", forHTTPHeaderField: "Accept")
                let imageRequest = request
                let data = try await ImageDataCache.shared.data(key: ImageDataCache.requestKey(imageRequest)) {
                    let (data, response) = try await URLSession.shared.data(for: imageRequest)
                    guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                        throw APIError.invalidResponse
                    }
                    return data
                }
                try Task.checkCancellation()
                guard let decoded = UIImage(data: data) else { throw APIError.invalidResponse }
                image = decoded
                loadedURL = url
            } catch {
                if !Task.isCancelled { failed = true }
            }
        }
    }
}
