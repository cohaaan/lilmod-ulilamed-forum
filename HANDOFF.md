# HANDOFF — Seforim reader "feels like Sefaria" redesign

You are picking up a scoped UX redesign of the in-app Seforim (Sefaria texts) reader. This
file is self-contained: read it top to bottom, then read the spec it points to, then build.

## The task in one line
Make the Seforim **reader** feel like the Sefaria app across four axes — continuous scroll,
a resource (connections) panel, paper typography, and per-segment bilingual interleave —
**without** copying Sefaria's GPL code or branding.

## Authority docs (read these first, in order)
1. `docs/seforim/READER_SEFARIA_FEEL.md` — **the spec.** Four target behaviors, current→target
   table, and the 3-phase risk-ordered build plan. This is your source of truth.
2. `SEFORIM_PLAN.md` — original feature plan (marked SHIPPED). Its **"Legal / data rules"**
   section is binding. Note: it is partially stale vs. the shipped code — the spec wins on conflict.
3. `AGENTS.md` / `CLAUDE.md` — repo-wide rules (Supabase, repository-only DB access, design bar).

## Guardrails (do not violate)
- **Clean-room.** Emulate the Sefaria *experience* only. Never copy their GPL-3.0 frontend
  code, CSS, or assets.
- **No Sefaria branding.** Name + logo are trademarked. The tab is "Seforim". Attribute the
  *source* and link back to the passage; don't present Sefaria chrome as ours.
- **Repository pattern.** All Sefaria HTTP goes through `lib/data/seforim_repository.dart`
  (singleton). Do not scatter `http` calls into widgets.
- Be a good API citizen: keep the existing caches + timeouts; continuous scroll must fetch the
  next section only as the user nears the end, one in-flight request per direction.

## Codebase orientation
Flutter app, Supabase backend. The Seforim feature is **already fully implemented and
`flutter analyze`-clean** — this is a look-and-feel redesign, not a rebuild. The data layer is
sound and stays; you're mostly changing the reader screen.

Files that matter (all under `lib/`):
- `screens/seforim/seforim_reader_screen.dart` — **the file you'll change most** (846 lines).
  Currently: global He/En/both `PopupMenuButton` toggle; verses render in `_SegmentCard`
  (stacked He then En) inside a `ListView`; tapping a verse toggles **inline** `_VerseCommentaries`
  (mekoros grouped by category → `_CommentatorTile` → `_LazyCommentText`); `_NavRow` gives
  Prev/Next buttons; `_Attribution` footer.
- `data/seforim_repository.dart` (368 lines) — Sefaria API + caching. Key methods:
  `fetchPassage(ref)` (he+en aligned segments, `next`/`prev`), `fetchRelated(verseRef)`
  (link metadata, `with_text=0`), `fetchSourceText(ref)` (lazy per-source text),
  `fetchShape`, `fetchIndex`, `search`. Caches are FIFO-capped at 30. Verse-alignment logic
  is deliberate — read the comments before touching it. Te'amim are stripped, nikud kept.
- `models/seforim.dart` — `SeforimPassage`, `SeforimSegment`, `SeforimComment`, `SeforimAttribution`, tree/shape nodes.
- `data/seforim_clipboard.dart` — copy-to-reply queue (singleton). `addSegmentForReply(...)`
  round-trips back to the originating thread. Don't break this contract.
- `theme/seforim_palette.dart`, `theme/app_colors.dart`, `theme/app_text.dart` — colors/fonts.
  Add a `paper`/cream surface here for Phase 1.
- `screens/seforim/{seforim_browse,seforim_category,seforim_book,seforim_search}_screen.dart`
  — drill-down that leads into the reader. Mostly untouched, but verify deep-links after Phase 2.

Fonts already in use: **Frank Ruhl Libre** (Hebrew), **EB Garamond** (English) via `google_fonts`.
Accent is indigo (`AppColors.indigo`).

## Build order (from the spec — do phases in order, commit each)
**Phase 1 — reader restructure** (highest impact, self-contained, do first):
paper background + typography air; per-segment He→En **interleave as the default** (demote the
He/En toggle to a menu option, keep it); **active-segment highlight** (selection state on the
list, not per-card) with Copy-to-reply surfacing on the selected verse only.
**Also fix the attribution gap here:** `_Attribution` shows only `versionTitle · license` — it
parses `versionSource` (`seforim_repository.dart:301`) but never renders it and has no passage
link-back, though the legal rules require both. Add the source + a `sefaria.org/{ref}` link-back.

**Phase 2 — continuous scroll:** accumulate an ordered `List<SeforimPassage>`; append the next
section (via current section's `next`) as the scroll nears the bottom; optional prepend via `prev`.
One in-flight fetch per direction; reuse the passage cache; no dup/dropped sections; deep-link to
a `:ref` and back-nav must still land correctly.

**Phase 3 — resource panel:** replace inline `_VerseCommentaries` with a **bottom sheet** (mobile)
/ side panel (wide) opened for the selected verse, with Sefaria-style category **filter chips**
(All / Commentary / Midrash / …). Reuse `fetchRelated` + `fetchSourceText` and the existing
category grouping. Copy-to-reply stays wired through `addSegmentForReply`.

## How to run & verify
```bash
flutter pub get
flutter analyze          # MUST stay clean — it is clean now
flutter test             # keep green
flutter run -d chrome    # visual check
```
The app is **auth-gated** (redirects to `/login`). Demo login: `philo@demo.lilmod.app` /
`Lilmod2026!`. Navigate: bottom tab **Seforim** → pick a category → book → a section opens the
reader. Good test refs: `Genesis 1` (simple, has next/prev + rich mekoros), a Talmud daf
(complex addressing), and something English-only (exercises the language-empty fallback).

## Definition of done
- All three phases implemented, or a clean checkpoint after each phase.
- `flutter analyze` clean, `flutter test` green.
- Guardrails honored (no GPL/branding), copy-to-reply → thread round-trip still works,
  deep-links + back-nav intact, attribution now shows source + passage link-back.
- Commit per phase with a clear message; do not force-push or touch unrelated files.

## Current working-tree state at handoff
These doc changes are the only uncommitted diff (everything else is committed at `96e4326`):
- `PLAN.md`, `MVPPLAN.md` — SUPERSEDED banners (they described a Django backend never built).
- `SEFORIM_PLAN.md` — SHIPPED status banner.
- `docs/seforim/READER_SEFARIA_FEEL.md` — the spec (new).
If you see these already committed, good — start from the spec.
