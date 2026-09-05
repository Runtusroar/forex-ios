import Foundation

struct NewsCommentPresentation: Identifiable, Sendable {
    let comment: NewsComment
    let parentAuthor: String?

    var id: String { comment.id }
    var isReply: Bool {
        guard let parent = comment.parentCommentID else { return false }
        return !parent.isEmpty && parent != comment.id
    }
    var author: String {
        let name = comment.authorName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Unknown author" : name
    }
    var body: String {
        let english = comment.text.en?.trimmingCharacters(in: .whitespacesAndNewlines)
        return english.flatMap { $0.isEmpty ? nil : $0 } ?? "English comment unavailable."
    }
    var reactionLabel: String? {
        comment.reactionCount.map { "\($0) \($0 == 1 ? "reaction" : "reactions")" }
    }

    init(comment: NewsComment, parentAuthor: String? = nil) {
        self.comment = comment
        self.parentAuthor = parentAuthor
    }
}

struct NewsCommentsPresentation: Equatable, Sendable {
    let loadedCount: Int
    let totalCount: Int
    let commentsComplete: Bool
    let nextCursor: String?

    var isPartial: Bool {
        !commentsComplete || nextCursor != nil || loadedCount < totalCount
    }
    var collectionLabel: String {
        if isPartial {
            return totalCount > loadedCount
                ? "\(loadedCount) of \(totalCount) comments available"
                : "\(loadedCount) comments available · Collection in progress"
        }
        return loadedCount == 1 ? "1 comment" : "\(loadedCount) comments"
    }

    static func rows(_ comments: [NewsComment]) -> [NewsCommentPresentation] {
        comments.map { comment in
            let parent = comments.first {
                $0.id == comment.parentCommentID && $0.id != comment.id && $0.articleID == comment.articleID
            }
            return NewsCommentPresentation(
                comment: comment,
                parentAuthor: parent.map { NewsCommentPresentation(comment: $0).author }
            )
        }
    }

    static func appendingPage(_ incoming: [NewsComment], to existing: [NewsComment]) -> [NewsComment] {
        var seen = Set(existing.map(\.id))
        return existing + incoming.filter { seen.insert($0.id).inserted }
    }
}

struct NewsCommentThreadRow: Identifiable, Sendable {
    let comment: NewsComment
    let parentAuthor: String?
    let depth: Int
    let isLastSibling: Bool
    let continuingAncestorDepths: [Int]
    let hasReplies: Bool
    var id: String { comment.id }
}

extension NewsCommentsPresentation {
    static func threadRows(_ comments: [NewsComment]) -> [NewsCommentThreadRow] {
        struct Key: Hashable {
            let article: String
            let comment: String
        }
        var indices: [Key: Int] = [:]
        var unique: [NewsComment] = []
        for comment in comments {
            let key = Key(article: comment.articleID, comment: comment.id)
            guard indices[key] == nil else { continue }
            indices[key] = unique.count
            unique.append(comment)
        }
        var parents: [Int: Int] = [:]
        for (index, comment) in unique.enumerated() {
            if let parentID = comment.parentCommentID, !parentID.isEmpty,
               let parent = indices[Key(article: comment.articleID, comment: parentID)], parent != index {
                parents[index] = parent
            }
        }
        // A malformed source cycle becomes a root instead of losing or endlessly nesting comments.
        var checked: Set<Int> = []
        for index in unique.indices where !checked.contains(index) {
            var chain: Set<Int> = []
            var cursor: Int? = index
            while let current = cursor, !checked.contains(current) {
                guard chain.insert(current).inserted else {
                    parents[current] = nil
                    break
                }
                cursor = parents[current]
            }
            checked.formUnion(chain)
        }
        var children: [Int: [Int]] = [:]
        var roots: [Int] = []
        for index in unique.indices {
            if let parent = parents[index] { children[parent, default: []].append(index) }
            else { roots.append(index) }
        }
        // Iterative depth-first traversal preserves source order among roots and siblings.
        var pending: [(index: Int, depth: Int, last: Bool, continuations: [Int])] = roots.enumerated().reversed().map {
            ($0.element, 0, $0.offset == roots.count - 1, [])
        }
        var result: [NewsCommentThreadRow] = []
        while let node = pending.popLast() {
            let replies = children[node.index] ?? []
            result.append(NewsCommentThreadRow(
                comment: unique[node.index],
                parentAuthor: parents[node.index].map { NewsCommentPresentation(comment: unique[$0]).author },
                depth: node.depth, isLastSibling: node.last,
                continuingAncestorDepths: node.continuations, hasReplies: !replies.isEmpty
            ))
            let continuations = node.continuations + (node.depth > 0 && !node.last ? [node.depth] : [])
            for (offset, child) in replies.enumerated().reversed() {
                pending.append((child, node.depth + 1, offset == replies.count - 1, continuations))
            }
        }
        return result
    }
}
