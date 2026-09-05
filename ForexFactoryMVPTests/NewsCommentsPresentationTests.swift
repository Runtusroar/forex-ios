import XCTest
@testable import ForexFactoryMVP

final class NewsCommentsPresentationTests: XCTestCase {
    func testReplyResolvesOnlyLoadedParentFromSameArticleWithoutReordering() {
        let reply = comment("reply", parent: "parent")
        let parent = comment("parent", author: "Market Reader")
        let rows = NewsCommentsPresentation.rows([reply, parent])
        XCTAssertEqual(rows.map(\.comment.id), ["reply", "parent"])
        XCTAssertEqual(rows[0].parentAuthor, "Market Reader")
        XCTAssertTrue(rows[0].isReply)
        XCTAssertFalse(rows[1].isReply)
        XCTAssertNil(NewsCommentsPresentation.rows([reply])[0].parentAuthor)
        XCTAssertTrue(NewsCommentsPresentation.rows([reply])[0].isReply)
        XCTAssertNil(NewsCommentsPresentation.rows([reply, comment("parent", article: "other")])[0].parentAuthor)
    }

    func testSelfParentDoesNotCreateReplyAndDuplicateIDsDoNotCrash() {
        let value = comment("one", parent: "one")
        let rows = NewsCommentsPresentation.rows([value, value])
        XCTAssertFalse(rows[0].isReply)
        XCTAssertNil(rows[0].parentAuthor)
    }

    func testMissingEnglishNeverFallsBackToTranslation() {
        let row = NewsCommentPresentation(comment: comment("one", english: " \n "))
        XCTAssertEqual(row.body, "English comment unavailable.")
    }

    func testReactionsPreserveZeroAndPluralizeOnlySuppliedCounts() {
        XCTAssertNil(NewsCommentPresentation(comment: comment("one")).reactionLabel)
        XCTAssertEqual(NewsCommentPresentation(comment: comment("one", reactions: 0)).reactionLabel, "0 reactions")
        XCTAssertEqual(NewsCommentPresentation(comment: comment("one", reactions: 1)).reactionLabel, "1 reaction")
        XCTAssertEqual(NewsCommentPresentation(comment: comment("one", reactions: 12)).reactionLabel, "12 reactions")
    }

    func testCollectionRemainsPartialWhenCursorOrSourceCountShowsMissingComments() {
        XCTAssertTrue(NewsCommentsPresentation(loadedCount: 2, totalCount: 2, commentsComplete: true, nextCursor: "next").isPartial)
        XCTAssertTrue(NewsCommentsPresentation(loadedCount: 2, totalCount: 4, commentsComplete: true, nextCursor: nil).isPartial)
        XCTAssertTrue(NewsCommentsPresentation(loadedCount: 0, totalCount: 0, commentsComplete: false, nextCursor: nil).isPartial)
        XCTAssertFalse(NewsCommentsPresentation(loadedCount: 2, totalCount: 2, commentsComplete: true, nextCursor: nil).isPartial)
        XCTAssertFalse(NewsCommentsPresentation(loadedCount: 0, totalCount: 0, commentsComplete: true, nextCursor: nil).isPartial)
    }

    func testAppendingPagePreservesAPIOrderAndSkipsRepeatedComments() {
        let existing = [comment("b"), comment("a")]
        let incoming = [comment("a"), comment("d"), comment("d"), comment("c")]
        XCTAssertEqual(NewsCommentsPresentation.appendingPage(incoming, to: existing).map(\.id), ["b", "a", "d", "c"])
    }

    func testThreadGroupsRepliesUnderParentsAndKeepsSiblingOrder() {
        let input = [comment("second", parent: "root"), comment("other"),
                     comment("root"), comment("first", parent: "root"),
                     comment("nested", parent: "second")]
        let rows = NewsCommentsPresentation.threadRows(input)
        XCTAssertEqual(rows.map(\.comment.id), ["other", "root", "second", "nested", "first"])
        XCTAssertEqual(rows.map(\.depth), [0, 0, 1, 2, 1])
        XCTAssertFalse(rows[2].isLastSibling)
        XCTAssertTrue(rows[3].isLastSibling)
        XCTAssertTrue(rows[4].isLastSibling)
        XCTAssertEqual(rows[3].continuingAncestorDepths, [1])
        XCTAssertTrue(rows[1].hasReplies)
        XCTAssertFalse(rows[4].hasReplies)
    }

    func testThreadNeverConnectsAnUnloadedOrForeignParent() {
        let orphan = comment("reply", parent: "missing")
        let rows = NewsCommentsPresentation.threadRows([orphan, comment("missing", article: "other")])
        XCTAssertEqual(rows.map(\.depth), [0, 0])
        XCTAssertNil(rows[0].parentAuthor)
        XCTAssertFalse(rows[1].hasReplies)
    }

    func testThreadPromotesOrphanWhenItsParentArrivesOnNextPage() {
        let orphan = comment("child", parent: "parent")
        XCTAssertEqual(NewsCommentsPresentation.threadRows([orphan])[0].depth, 0)
        let rows = NewsCommentsPresentation.threadRows([orphan, comment("parent", author: "Alex")])
        XCTAssertEqual(rows.map(\.comment.id), ["parent", "child"])
        XCTAssertEqual(rows[1].parentAuthor, "Alex")
        XCTAssertEqual(rows[1].depth, 1)
    }

    func testThreadBreaksCyclesAndEmitsEachCommentOnce() {
        let input = [comment("a", parent: "b"), comment("b", parent: "a"),
                     comment("self", parent: "self"), comment("a", parent: "b")]
        let rows = NewsCommentsPresentation.threadRows(input)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(Set(rows.map(\.comment.id)), ["a", "b", "self"])
        XCTAssertEqual(rows.map(\.depth), [0, 1, 0])
    }

    func testLastBranchStopsItsAncestorsContinuation() {
        let rows = NewsCommentsPresentation.threadRows([
            comment("root"), comment("a", parent: "root"), comment("b", parent: "root"),
            comment("deep", parent: "b")
        ])
        XCTAssertEqual(rows.last?.continuingAncestorDepths, [])
        XCTAssertEqual(rows.last?.depth, 2)
    }

    private func comment(
        _ id: String, article: String = "article", parent: String? = nil,
        author: String = "Reader", english: String? = "A considered view.", reactions: Int? = nil
    ) -> NewsComment {
        NewsComment(
            commentID: id, articleID: article, parentCommentID: parent, authorName: author,
            publishedAt: nil, publishedAtSourceText: nil,
            text: LocalizedText(en: english, zhHans: "中文评论"),
            permalink: URL(string: "https://www.forexfactory.com/news/1#\(id)")!, reactionCount: reactions
        )
    }
}
