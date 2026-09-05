# Right-aligned dates and threaded comments — 2026-09-05

The date at the top of Calendar, News and Contracts now aligns to the right. The removed Forex Factory brand label stays removed. Settings retains its date-free header. Full Last updated timestamps remain unchanged.

## Comment relationships

Article comments now render as a tree built from same-article parent IDs. Root and sibling order follows their source order, and descendants are grouped under their parent. The independent Latest Comments feed keeps its flat feed behavior.

- A trunk starts below the parent identity marker.
- Intermediate replies use a continuing trunk and horizontal branch.
- The final reply ends its branch with a small elbow.
- Nested replies retain ancestor trunks where a later sibling still follows.
- Connected replies omit the redundant Reply to label; their author accessibility label still names the parent.
- Missing parents remain unconnected roots with reply context. When a parent arrives in another page, its loaded replies become attached.
- Duplicate comments are skipped and malformed cycles are broken deterministically.
- Visual nesting is capped at three levels normally and two at accessibility sizes. Deeper replies preserve explicit parent context and are not given a misleading additional branch. No comments are hidden by the cap.

The detail retains one eager scrolling stack; tree lines are noninteractive shapes in reserved gutters, not separate scroll views or per-row geometry measurements.

## Native visual evidence

Captured with controlled fixtures on the simulator; saved images were inspected directly.

- [News date at upper right](02-news-light.png)
- [Article/comment boundary](19-article-discussion-boundary.png)
- [Branching and nested replies](21-branching-thread.png)
- [Dark appearance](22-branching-thread-dark.png)
- [Accessibility text](23-branching-thread-large.png)

The branching examples show a parent with two children, one grandchild, and a separate root. Screenshot 23 is intentionally scrolled into the reply group. The full capture harness is archived here outside the ordinary test target.

## Verification

Five relationship tests were added. Before implementation they failed against the flat presentation as expected; they now pass, including out-of-order input, siblings, unloaded/foreign parents, late parent arrivals, duplicate IDs and cycles.

The integrated simulator run passed 67 tests (65 ordinary tests and two capture tests), with zero failures. A subsequent dedicated branching capture test also passed. The article scroll regression kept all six reverse-scroll heights at 11680 pt and requested each of nine images once.

Logs: `/private/tmp/forex-thread-tree-red.log`, `/private/tmp/forex-thread-tree-green.log`, `/private/tmp/forex-thread-tree-capture.log`, `/private/tmp/forex-thread-tree-device.log`. Source whitespace check passed. Device installation status is recorded in `verification.txt`.

This is not an exhaustive VoiceOver or live network timing audit. A newly arriving parent can legitimately regroup its loaded replies. Native fixture screenshots demonstrate layout, not live market data.
