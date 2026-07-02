# Seforim — Sefaria-fidelity screenshots

Rendered from the **real widgets against the live Sefaria API** (no mock data)
via `lib/preview_seforim_main.dart` on `flutter run -d web-server`, mobile
viewport 390×844. Typography is the Sefaria-fidelity set: Cardo (English serif),
Taamey Frank CLM (Hebrew), Roboto (UI sans) — see
`docs/seforim/SEFARIA_DESIGN_TOKENS.md`.

| File | Shows |
|---|---|
| `1-browse.png` | Library root — colour-coded corpora, Cardo titles, Hebrew names, sans descriptions |
| `2-category.png` | Mishnah category — serif heading over its colour rule, hairline sub-rows |
| `3-toc.png` | Mishnah Peah TOC — Cardo title, navy Start Reading, chapter-box grid |
| `4-reader.png` | Reader (Mishnah Peah 2) — centered section numeral, Taamey Frank He + grey Cardo En |
| `5-resources.png` | Verse selected (pale-blue wash) → RESOURCES sheet, filter chips, Commentary (13) |

These supersede the earlier mock-data preview-harness renders from the initial
Phase 1–3 pass (which used Frank Ruhl Libre / EB Garamond on a cream surface).
