# Seforim Reader — "feels like Sefaria" redesign spec

Status: **proposed** · Scope: `lib/screens/seforim/seforim_reader_screen.dart` (+ small
repo/model additions). This is a **UX/visual-fidelity** effort, not a rebuild — the data
layer (`seforim_repository.dart`) is sound and stays.

## Why
The reader is functionally complete and `flutter analyze`-clean, but it does not *feel* like
the Sefaria app. The user wants the reading experience to match Sefaria across four axes
(all four confirmed): continuous scroll, a resource panel, paper typography, and per-segment
bilingual interleave.

## Guardrails (binding — from `SEFORIM_PLAN.md`)
- **Clean-room only.** Emulate the *experience* (layout, typography feel, interaction
  patterns). Do **not** copy Sefaria's GPL-3.0 frontend code, CSS, or assets.
- **No Sefaria branding.** Name/logo are trademarked. Tab stays "Seforim". Attribute the
  *source* and link back to the passage; never present Sefaria chrome as our own.
- Stay a good API citizen: the existing caches + timeouts carry over; continuous scroll must
  not hammer the API (fetch next section only as the user nears the end).

## Current state → target

| Axis | Now | Target (Sefaria feel) |
|---|---|---|
| **Navigation** | Discrete section with Prev/Next buttons (`_NavRow`), `_load()` replaces the passage. | Continuous scroll: sections append as you scroll; `next`/`prev` drive lazy prepend/append into one list. |
| **Connections** | Mekoros expand **inline** under the verse (`_VerseCommentaries`). | Tap verse → it highlights → connections open in a **bottom sheet** (mobile) / side panel (wide) with category filter chips. |
| **Layout** | Global He/En/both toggle flips every verse. | **Per-segment interleave** (He then En) as the default flowing column; keep a language control as a secondary option. |
| **Chrome** | White + indigo cards, "Copy to reply" chip on every verse. | Paper/cream background, quieter chrome, **active-segment highlight**; Copy-to-reply surfaces on the *selected* verse (or in the resource panel), not always-on. |

## Implementation shape (risk-ordered)

**Phase 1 — reader restructure (the "feel" foundation).** Highest impact, self-contained.
- Paper background + typography pass: introduce a `paper` surface color, drop the boxed
  card look, tune He (Frank Ruhl) / En (EB Garamond) line-height/size to Sefaria-like air.
- Per-segment interleave becomes the default render; demote the He/En toggle to a menu option
  (keep it — it's genuinely useful and Sefaria has it too).
- Active-segment highlight: tapping a verse selects it (state on the list, not per-card),
  and per-verse actions (Copy to reply) appear for the selected verse only.
- Acceptance: reads like a page, not a form; `flutter analyze` clean.

**Phase 2 — continuous scroll.**
- Repo: add a way to fetch the *adjacent* section and expose an ordered list of sections in
  the screen (`List<SeforimPassage>` accumulated). Append when the scroll nears the bottom
  using the current section's `next`; optional prepend using `prev`.
- Guard: only one in-flight fetch per direction; respect the existing passage cache.
- Acceptance: scrolling past the end of Genesis 1 flows into Genesis 2 with no button tap;
  no duplicate/dropped sections; back-nav and deep-link to a `:ref` still land correctly.

**Phase 3 — resource panel.**
- Replace inline `_VerseCommentaries` with a bottom sheet opened for the *selected* verse,
  reusing `fetchRelated` / `fetchSourceText` and the existing category grouping.
- Category **filter chips** across the top (All / Commentary / Midrash / …), Sefaria-style.
- Copy-to-reply lives in the panel per source (already wired via `addSegmentForReply`).
- Acceptance: tap verse → panel; filter chips work; copy-to-reply still round-trips to thread.

## Deferred / open
- **Attribution gap (carry-over, do in Phase 1):** the reader footer shows only
  `versionTitle · license` — it parses `versionSource` but never renders it and has no
  passage link-back, though `SEFORIM_PLAN.md`'s legal rules require both. Fix while touching
  the reader.
- Wide-screen (tablet/web) side-panel layout vs. mobile bottom sheet — Phase 3 detail.
- Whether to keep the pasted-source block Hebrew-only (current) or restore He+En per plan M4.

## Note
`SEFORIM_PLAN.md` is now partially stale vs. the shipped code (e.g. M4's paste format). Treat
*this* doc as the authority for the reader redesign; update `SEFORIM_PLAN.md`'s status notes
if the two conflict further.
