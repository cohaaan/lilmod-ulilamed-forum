# SEFORIM_PLAN.md — In-app Sefaria texts ("Seforim" tab)

> ✅ **STATUS: SHIPPED (Milestones 0–5).** This began as a build plan; the feature is now
> implemented and committed. Code: `lib/data/seforim_repository.dart`, `lib/models/seforim.dart`,
> `lib/data/seforim_clipboard.dart`, `lib/screens/seforim/` (browse, category, book, reader, search),
> plus `composer_draft_store.dart`. Read the milestones below as a description of what exists
> and the design rationale — **not** as an open to-do list. The "Legal / data rules" section is
> still binding. Live open questions are in the final section.

Goal: a 5th bottom-nav tab **Seforim** that browses the full Sefaria library,
reads texts natively (Hebrew RTL + English), and lets a user **copy a source
straight into the reply they're writing** — then return to the exact thread/reply
they left, with nothing lost.

Decisions locked:
- **Thread detail moves into the Forums tab branch** (not a root modal) so the bottom
  bar stays visible and the live reply survives a tab switch (IndexedStack keep-alive).
- **Native Flutter reader** (no WebView; no copying their GPL frontend code).
- **Full library tree** from `/api/index`.

---

## Legal / data rules (must honor)
- Build our **own UI on Sefaria's public API**. Do **not** copy their GPL-3.0 frontend code.
- Texts are mostly Public Domain / CC0 / CC-BY. The API returns a `license` and
  `versionSource` per version — **show attribution** (publisher + source) in the reader
  and in any pasted source block when the license requires it.
- **"Sefaria" name + logo are trademarked.** Tab is "Seforim". Attribute the *source*,
  link back to the passage URL, don't present Sefaria branding as our own.
- Be a good API citizen: cache aggressively, debounce search, reasonable request rate.

## API endpoints (verified live, base `https://www.sefaria.org`)
- `GET /api/index/` → full category/book tree (browse).
- `GET /api/shape/{title}` → book structure / table of contents (chapter counts, complex nodes).
- `GET /api/v3/texts/{ref}?version=hebrew&version=english&return_format=text_only`
  → passage. Key fields: `versions[]` (`text`, `language`, `direction`, `versionTitle`,
  `license`, `versionSource`), `ref`, `heRef`, `next`, `prev`, `book`, `isComplex`.
- `GET /api/search-wrapper` (POST/GET) → search across texts.
- Passage web URL for "open/link back": `https://www.sefaria.org/{ref}` (spaces→`_`).

---

## Milestone 0 — Plumbing
- Add `http: ^1.2.0` to `pubspec.yaml`.
- `lib/config/seforim_config.dart`: base URL, default versions, request timeout.
- New folder `lib/screens/seforim/`, `lib/data/seforim_repository.dart`,
  `lib/models/seforim.dart`.

## Milestone 1 — Data layer
`lib/models/seforim.dart`:
- `SeforimCategory { name, heName, contents: List<dynamic> }` (tree node; contents may be
  sub-categories or books).
- `SeforimBook { title, heTitle, categories, primaryCategory }`.
- `BookShape { title, isComplex, chapters: List<int> /* lengths */, nodes }`.
- `Passage { ref, heRef, segments: List<Segment>, next, prev }`.
- `Segment { he, en, citation, heCitation }`.
- `Attribution { versionTitle, source, license }`.

`lib/data/seforim_repository.dart` (singleton, mirrors forum_repository style):
- `fetchIndex()` → `List<SeforimCategory>` (memoized in-memory + simple disk cache later).
- `fetchShape(title)` → `BookShape`.
- `fetchPassage(ref)` → `Passage` (requests he+en, `return_format=text_only`; parse the
  two versions into aligned segments; handle missing en/he gracefully).
- `search(query)` → results list.
- Add `seforimRepository` to `lib/data/repositories.dart`.
- Standardize errors like the existing repos (so `AsyncValue`-style screens can show them).

## Milestone 2 — Browse + read screens (`lib/screens/seforim/`)
Mirror the Forums drill-down and use existing `soft_card` / list-row styling.
- `SeforimBrowseScreen` — top-level categories from `/api/index`; tap → recurse into
  sub-categories or into a book. **Full tree**: recursive category navigation
  (route `/seforim`, `/seforim/c/:path` where `:path` is a slash-encoded category path).
- `SeforimBookScreen` (`/seforim/book/:title`) — uses `/api/shape`; renders TOC.
  Handle **complex texts** (node tree) and **simple texts** (chapter list). For commentaries
  /linked texts, show their structure too.
- `SeforimReaderScreen` (`/seforim/read/:ref`) — the reading view:
  - Hebrew column (RTL, serif Hebrew font via google_fonts e.g. Frank Ruhl) + English.
  - View toggle: Hebrew-only / English-only / both.
  - Prev/next section via `next`/`prev`.
  - Per-segment actions: **Copy** (system clipboard) and **Copy to reply** (source clipboard, see M4).
  - Attribution footer (versionTitle, source link, license).

## Milestone 3 — Thread-into-Forums refactor + draft persistence
- In `app_router.dart`: move `/threads/:id` from the root-navigator modal **into the
  Forums `StatefulShellBranch`** as a nested route under `/forums`. Bottom bar now visible
  on the thread screen; IndexedStack keeps it alive across tab switches.
  - Keep article/account as-is for now (only thread needs the keep-alive flow).
  - Verify scroll position + reply text persist when switching tabs and back.
- `lib/data/composer_draft_store.dart` (tiny `ChangeNotifier`): `Map<threadId, {text, replyingToId}>`.
  ThreadDetailScreen writes on change, restores on init — belt-and-suspenders so a full
  pop (not just tab switch) also restores. Clear on successful send.

## Milestone 4 — The copy → insert flow (the headline feature)
- `lib/data/seforim_clipboard.dart` (`ChangeNotifier`): holds queued copied sources
  (formatted block: `heRef` + Hebrew + English + link). Survives tab switches (singleton).
- In `SeforimReaderScreen`, **Copy to reply** pushes a formatted block onto the clipboard
  and shows a snackbar "Added to reply" (also copies plain text to system clipboard).
- In `thread_detail_screen.dart` `_ReplyBar`:
  - When `seforimClipboard` is non-empty, show a chip: **"N source(s) ready · Insert"**.
  - Tapping inserts the formatted block(s) into `_replyController` at the cursor and clears
    the queue. Also add a 📖 button in the reply bar to **jump to the Seforim tab** mid-reply.
- Source block format (plain text, since post bodies are plain text today):
  ```
  > {heRef}
  > {Hebrew}
  > {English}
  > — {source}, sefaria.org/{ref}
  ```
  (If we later add markdown rendering to posts, upgrade this to real blockquote/links.)

## Milestone 5 — Bottom nav + search + polish
- `scaffold_with_nav_bar.dart`: add 5th tab "Seforim" (distinct icon, e.g.
  `Icons.auto_stories_outlined` / `auto_stories`); confirm 5 tabs fit on small screens.
- `app_router.dart`: add the Seforim `StatefulShellBranch` (branch index 4).
- Seforim search screen (`/api/search-wrapper`) with debounce; tap result → reader at ref.
- Hebrew typography pass (font, line height, nikud rendering), loading/empty/error states,
  offline cache of index tree + last-read passages.
- `flutter analyze` clean, basic widget test for repository parsing.

---

## Open questions (not blocking M0–M2)
1. Pasted-source format — keep the plain blockquote above, or invest in markdown/HTML
   rendering for forum posts so sources render richly? (Affects M4 + post rendering.)
2. Default reader language — both columns, or Hebrew-first with English on tap?
3. Should "Copy to reply" be limited when no reply is in progress (queue and prompt to pick
   a thread), or only show the insert chip when actively in a thread? (v1: only in-thread.)
4. Cache depth — memory-only for v1, or persist index/passages to disk (e.g. shared_prefs/
   sqlite) for offline + speed?

## Risk notes
- The thread-route refactor (M3) touches navigation; test deep links to `/threads/:id`
  and the auth redirect still work.
- `/api/index` is large — fetch once, cache, lazy-render the tree.
- Complex texts (Talmud, commentaries) have nested structures — `/api/shape` handling in M2
  is the trickiest part of "full library tree"; budget time there.
