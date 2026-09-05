# News header and comments reference research

Date: 2026-09-05, Asia/Shanghai. Scope: research only. No application code changes or installation in this pass.

The user rejected the previous large Discussion/Comments heading and broad tinted discussion section. That design direction is superseded by the recommendations below; the currently installed application has not been changed in this research pass.

## Reference evidence

Two public Forex Factory news detail pages were inspected in the browser, including a 393 × 852 viewport:

- https://www.forexfactory.com/news/1416555-trump-we-should-be-at-one-percent-or#comments
- https://www.forexfactory.com/news/1416483-the-us-employment-situation-august-2026#post

Saved and visually inspected captures:

- `01-comments-desktop.png`: first story, desktop discussion structure.
- `02-comments-mobile.png`: first story, article/comment boundary and nested replies at mobile width.
- `03-second-story-comments.png`: second story, multiple parent/reply groups. An advertisement overlays the bottom; observations use the unobscured upper threads.

Direct observations: a narrow blue section bar marks Comments; small avatars establish a left identity gutter; author and subdued relative time sit together above the body; compact Reply/reaction metadata follows the text. Child replies indent beneath their parent and use a faint connecting line. Top-level threads have subtle horizontal separation. The source does use a pale cool background; it does not use the app's large Discussion kicker and oversized Comments heading. Composer and reply controls belong to the source website and were not submitted or functionally tested.

## News header diagnosis

Read-only inspection of `News/NewsListView.swift` and `Components/InterfaceComponents.swift` confirms that the timestamp is inside PageHeader, followed by the header's bottom padding, then a separate right-aligned impact-filter row with its own bottom padding. Both controls reserve substantial touch height. Independent rows and accumulated spacing create the apparent excess whitespace.

Recommendation: put Updated and All impact in one shared compact toolbar above the category picker. Keep full date, time to seconds, and timezone. A representative label is `Updated 2026-09-05 16:50:32 UTC+8`. Use a shared 44–48 pt minimum touch row and approximately 8–12 pt separation from the picker. These are proposed native sizes, not measurements of the website. At accessibility text sizes allow the timestamp to wrap within its group rather than truncating essential information.

## Proposed native adaptation

- Replace the large Discussion/Comments block with a compact, square-edged, subtly tinted `Comments (count)` section bar, approximately 16–17 pt semibold. Keep its separation from the article deliberate but restrained.
- Use small 28–32 pt identity markers, an emphasized author, subdued timestamp, and 15–16 pt comment text. Preserve comfortable line spacing; do not copy the website's tiny text.
- Align each body under the author, with the identity gutter at the left. Put reactions and View original in a compact footer.
- Visually group replies beneath parents using one level of indentation and a very faint short connector restricted to the reply gutter. Avoid deep indentation, individual card boxes, or repeated heavy borders.
- Use a continuous neutral reading surface and the compact section bar to establish the boundary. Broad section tinting and a second Discussion label are removed from the proposed direction.
- Preserve English UI, full timestamp precision, square geometry, and the stable single eager scrolling stack introduced for the detail-page scrolling bug.

The current comment model supplies author names, parent IDs, timestamps, reaction counts, and original links, but not avatar URLs. A small neutral identity marker is feasible; real avatar support would require additional source data. Do not introduce a nonfunctional composer, Reply action, or voting controls into the current read-only app.

## Limits

This is a visual reference study of two public pages, not a complete accessibility or authenticated interaction audit. Mobile-width browser screenshots are not native iPhone screenshots. Native spacing and Dynamic Type behavior still require implementation-time review. No build or tests were necessary for this research-only pass.
