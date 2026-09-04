import SwiftUI

struct NewsCommentCard: View {
    let comment: NewsComment

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Text(comment.authorName.uppercased())
                    .font(EditorialTheme.smallCaps)
                    .tracking(0.4)
                Spacer()
                if let date = comment.publishedAt {
                    Text(date, style: .relative)
                        .font(EditorialTheme.metadata)
                        .foregroundStyle(EditorialTheme.mutedInk)
                }
            }
            BilingualText(
                english: comment.text.en ?? "Comment",
                chinese: comment.text.zhHans,
                role: .body,
                englishFont: .body
            )
            if let reactions = comment.reactionCount, reactions > 0 {
                Text("REACTIONS \(reactions)")
                    .font(EditorialTheme.smallCaps)
                    .foregroundStyle(EditorialTheme.mutedInk)
            }
            EditorialRule()
        }
        .padding(.vertical, 8)
    }
}
