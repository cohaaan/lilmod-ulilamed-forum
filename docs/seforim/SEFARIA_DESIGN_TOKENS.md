# Sefaria design tokens (measured)

Measured 2026-07-02 from sefaria.org with a headless-Chrome probe (mobile
viewport 390×844): computed styles of rendered elements + the loaded CSS's
`@font-face` rules. These are plain facts (colour values, font names, sizes) —
re-declared as our own constants in `lib/theme/seforim_palette.dart`. **No
Sefaria code or assets are copied.**

## Fonts

| Voice | Sefaria actual | Our mapping | License |
|---|---|---|---|
| English serif | `Cardo` (self-hosted), then `adobe-garamond-pro` | `GoogleFonts.cardo` — the *same* face, from Google Fonts | OFL |
| Hebrew | `Taamey Frank CLM` (Medium + Bold TTFs) | Bundled `assets/fonts/TaameyFrankCLM-*.ttf`, family `TaameyFrank` | Culmus project, GPL v2 + font-embedding exception (`assets/fonts/TAAMEY_FRANK_LICENSE.txt`) |
| UI sans | `Roboto` | `GoogleFonts.roboto` | Apache 2.0 |

Helpers: `SeforimText.serif / .hebrew / .sans` in `seforim_palette.dart`.

## Type scale (mobile reader, measured)

| Element | Font | Size / line-height | Color |
|---|---|---|---|
| Hebrew segment | Taamey Frank | 26.8px / 1.6 | #000 |
| English translation | Cardo | 22px / 1.6 | #666 |
| Segment number | Roboto w100 | 12px | #000 (we use #999) |
| Section number heading | Cardo w100, ls 1px | 24px | #000 |
| Reader header title | Cardo | 18px | #000 |
| Library category title | Cardo | 24px / 1.3 | #000 |
| Library description | Roboto | 14px / 1.29 | #666 |
| Library page H1 | Roboto w500 | 22px | #666 |
| TOC book title | Cardo | 30px | #000 |
| TOC section link | Cardo w100 | 18px | #666 on #FBFBFA |
| Buttons | Roboto | 16px | #FFF on #18345D |

## Colors

Neutrals: page **#FFFFFF** (white, not cream) · secondary text **#666666** ·
tertiary **#999999** · faint pane **#FBFBFA** · hairline **#EDEDEC** ·
action navy **#18345D** · selected-segment highlight **≈#EDF4FA** (pale blue).

Category bars (4px top rule on library rows):

| Category | Hex | | Category | Hex |
|---|---|---|---|---|
| Tanakh | #004E5F | | Tosefta | #00827F |
| Mishnah | #5A99B7 | | Chasidut | #97B386 |
| Talmud | #CCB479 | | Musar | #7C416F |
| Midrash | #5D956F | | Responsa | #CB6158 |
| Halakhah | #802F3E | | Reference | #D4886C |
| Kabbalah | #594176 | | Second Temple | #C6A7B4 |
| Liturgy | #AB4E66 | | Jewish Thought | #7F85A9 |

## Structure notes (from screenshots)

- Library rows: 4px colour bar on **top level only**; sub-levels separate with
  hairlines.
- TOC: Cardo 30 title → small-caps category → navy "Start Reading" → "Chapter"
  sans label → grid of ~50px faint boxes with serif grey numerals.
- Reader: centered section numeral over a short rule; He then En per segment;
  selected segment gets the pale-blue wash + its resources open (RESOURCES
  panel: letter-spaced caps header, related categories with counts).

## Re-probing

The probe scripts live at `/tmp/sefaria-probe/{probe,shoot}.js` during a
session (puppeteer-core + system Chrome; not committed). `probe.js` visits
sefaria.org and dumps computed styles; `shoot.js` screenshots our own app via
`flutter run -d web-server --web-port=8123 --target=lib/preview_seforim_main.dart`
(hash URLs: `http://localhost:8123/#/seforim/...`). `lib/preview_seforim_main.dart`
serves the Seforim flow with no Supabase/auth against the live Sefaria API.
