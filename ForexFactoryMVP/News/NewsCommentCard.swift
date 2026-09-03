import SwiftUI

struct NewsCommentCard: View {
    let comment: NewsComment

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(comment.authorName, systemImage: "person.crop.circle")
                    .font(.caption.weight(.semibold))
                Spacer()
                if let date = comment.publishedAt {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            BilingualText(
                english: comment.text.en ?? "Comment",
                chinese: comment.text.zhHans,
                englishFont: .body
            )
            if let reactions = comment.reactionCount, reactions > 0 {
                Label("\(reactions)", systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
