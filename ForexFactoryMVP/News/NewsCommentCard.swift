import SwiftUI

struct NewsCommentCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let comment: NewsComment
    var parentAuthor: String? = nil
    var showsPermalink = false
    var bodyFont: Font = .subheadline
    var showsReplyContext = true
    var reservesThreadGutter = false

    private var presentation: NewsCommentPresentation {
        NewsCommentPresentation(comment: comment, parentAuthor: parentAuthor)
    }

    var body: some View {
        HStack(alignment: .top, spacing: EditorialSpacing.related) {
            if !dynamicTypeSize.isAccessibilitySize {
                identity
            } else if reservesThreadGutter {
                Color.clear.frame(width: 12, height: 1).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: EditorialSpacing.inline) {
                Text(presentation.author)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EditorialTheme.accent)
                    .accessibilityLabel(authorAccessibilityLabel)
                if let date = comment.publishedAt {
                    Text(EditorialDateFormatter.timestamp(date))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(EditorialTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if presentation.isReply && showsReplyContext {
                    Label(
                        parentAuthor.map { "Reply to \($0)" } ?? "Reply to an earlier comment",
                        systemImage: "arrow.turn.down.right"
                    )
                    .font(.caption)
                    .foregroundStyle(EditorialTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
                }
                Text(presentation.body)
                    .font(bodyFont)
                    .foregroundStyle(EditorialTheme.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, EditorialSpacing.inline)
                footer
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, EditorialSpacing.content)
    }

    private var authorAccessibilityLabel: String {
        guard presentation.isReply, !showsReplyContext else { return presentation.author }
        return presentation.author + ", reply to " + (parentAuthor ?? "an earlier comment")
    }

    private var identity: some View {
        Text(String(presentation.author.prefix(1)).uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(EditorialTheme.accent)
            .frame(width: 28, height: 28)
            .background(EditorialTheme.subtleSurface)
            .overlay { Rectangle().strokeBorder(EditorialTheme.rule, lineWidth: 0.5) }
            .accessibilityHidden(true)
    }

    private var footer: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            if let reactions = presentation.reactionLabel {
                Label(reactions, systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
            if showsPermalink {
                Link(destination: comment.permalink) {
                    HStack(spacing: 4) {
                        Text("View original")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.caption.weight(.medium))
                    .frame(minHeight: 44, alignment: .leading)
                }
                .foregroundStyle(EditorialTheme.accent)
                .accessibilityLabel("View comment on Forex Factory")
            }
        }
    }
}
