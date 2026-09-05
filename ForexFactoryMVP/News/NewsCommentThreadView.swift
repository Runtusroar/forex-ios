import SwiftUI

struct NewsCommentThreadView: View {
    let comments: [NewsComment]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var authorHalfHeight = 9.0

    private var maximumDepth: Int { dynamicTypeSize.isAccessibilitySize ? 2 : 3 }
    private var step: CGFloat { dynamicTypeSize.isAccessibilitySize ? 16 : 24 }
    private var trunkOffset: CGFloat { dynamicTypeSize.isAccessibilitySize ? 6 : 14 }
    private var anchorY: CGFloat {
        EditorialSpacing.content + (dynamicTypeSize.isAccessibilitySize ? authorHalfHeight : 14)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(NewsCommentsPresentation.threadRows(comments)) { row in
                if row.depth == 0 { EditorialRule() }
                NewsCommentCard(
                    comment: row.comment, parentAuthor: row.parentAuthor, showsPermalink: true,
                    showsReplyContext: row.depth == 0 || row.depth > maximumDepth,
                    reservesThreadGutter: true
                )
                .padding(.leading, CGFloat(min(row.depth, maximumDepth)) * step)
                .background {
                    CommentBranchLines(
                        row: row, maximumDepth: maximumDepth, step: step,
                        trunkOffset: trunkOffset, anchorY: anchorY
                    )
                    .stroke(EditorialTheme.mutedInk.opacity(0.32), lineWidth: 1)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

private struct CommentBranchLines: Shape {
    let row: NewsCommentThreadRow
    let maximumDepth: Int
    let step: CGFloat
    let trunkOffset: CGFloat
    let anchorY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        func vertical(_ x: CGFloat, from start: CGFloat, to end: CGFloat) {
            path.move(to: CGPoint(x: x, y: start))
            path.addLine(to: CGPoint(x: x, y: end))
        }
        for depth in row.continuingAncestorDepths where depth <= maximumDepth {
            vertical(CGFloat(depth - 1) * step + trunkOffset, from: 0, to: rect.height)
        }
        if row.depth > 0 && row.depth <= maximumDepth {
            let x = CGFloat(row.depth - 1) * step + trunkOffset
            let endX = CGFloat(row.depth) * step
            if row.isLastSibling {
                let radius: CGFloat = 4
                vertical(x, from: 0, to: anchorY - radius)
                path.addQuadCurve(to: CGPoint(x: x + radius, y: anchorY),
                                  control: CGPoint(x: x, y: anchorY))
                path.addLine(to: CGPoint(x: endX, y: anchorY))
            } else {
                vertical(x, from: 0, to: rect.height)
                path.move(to: CGPoint(x: x, y: anchorY))
                path.addLine(to: CGPoint(x: endX, y: anchorY))
            }
        }
        if row.hasReplies && row.depth < maximumDepth {
            // Begin below the author's marker, in the reserved identity gutter.
            vertical(CGFloat(row.depth) * step + trunkOffset, from: anchorY + 14, to: rect.height)
        }
        return path
    }
}
