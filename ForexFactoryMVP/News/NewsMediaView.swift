import SwiftUI
import UIKit

struct NewsMediaPresentation: Equatable, Sendable {
    enum State: Equatable, Sendable {
        case image(path: String)
        case processing
        case unavailable
    }

    let state: State

    init(media: NewsMedia) {
        if media.downloadState == .complete, let path = media.url {
            state = .image(path: path)
        } else if media.downloadState == .pending || media.downloadState == .processing {
            state = .processing
        } else {
            state = .unavailable
        }
    }

    var hasDisplayableImage: Bool {
        if case .image = state { true } else { false }
    }
}

struct NewsMediaView: View {
    let media: NewsMedia
    let model: NewsViewModel

    @State private var image: UIImage?
    @State private var failed = false

    private var presentation: NewsMediaPresentation {
        NewsMediaPresentation(media: media)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Group {
                switch presentation.state {
                case .image:
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else if failed {
                        unavailableView
                    } else {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 120)
                    }
                case .processing:
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("MEDIA PROCESSING")
                            .font(EditorialTheme.smallCaps)
                            .foregroundStyle(EditorialTheme.mutedInk)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                case .unavailable:
                    unavailableView
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
        .task(id: mediaTaskID) {
            image = nil
            failed = false
            await load()
        }
    }

    private var mediaTaskID: String {
        "\(media.id)-\(media.downloadState.rawValue)-\(media.url ?? "")"
    }

    private var unavailableView: some View {
        ContentUnavailableView {
            Label("Image unavailable", systemImage: "photo.badge.exclamationmark")
        } actions: {
            Button {
                failed = false
                Task { await load() }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        .frame(minHeight: 120)
    }

    private func load() async {
        guard case .image(let path) = presentation.state else {
            return
        }
        guard image == nil, !failed else { return }
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
