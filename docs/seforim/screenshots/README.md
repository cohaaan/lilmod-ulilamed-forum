# Seforim reader redesign — screenshots

Visual reference for the "feels like Sefaria" reader redesign
(`docs/seforim/READER_SEFARIA_FEEL.md`, Phases 1–3).

These were rendered from a **throwaway preview harness with mock Genesis 1 data**,
not the live app — Supabase (auth) and the Sefaria API were unreachable in the
build environment. The harness renders the real `SeforimReaderScreen` widget
tree, so layout, interaction, and typography (Frank Ruhl Libre / EB Garamond on
the paper surface) are faithful; only the data is stubbed.

| File | Shows |
|---|---|
| `4-narrow-reading.png` | Paper reading view, per-verse He→En interleave, section heading (Phase 1 + 2) |
| `5-narrow-sheet.png` | Mobile: tap a verse → connections bottom sheet with filter chips (Phase 3) |
| `2-wide-panel.png` | Wide: selected verse highlighted + docked connections rail (Phase 1 + 3) |
| `3-wide-panel-open.png` | Wide: a commentator expanded with He+En text and "Copy to reply" (Phase 3) |
| `1-wide-reading.png` | Wide reading view with the empty connections rail placeholder |

A real `flutter run -d chrome` pass against live Sefaria (Genesis 1→2 continuous
scroll, a Talmud daf, an English-only text) is still worth doing before merge.
