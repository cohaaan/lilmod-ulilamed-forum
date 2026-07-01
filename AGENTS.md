# AGENTS.md — Lilmod Ulilamed forum

A real Flutter forum app backed by **Supabase**. Not mock data — threads, replies,
likes, bookmarks, auth all hit the live DB.

## Key facts
- Supabase project ref: `lxcbaortmbhjsthycdkt` (org `cohaaan's Org`). URL + publishable key in `lib/config/supabase_config.dart`.
- All DB access goes through `lib/data/forum_repository.dart` and `auth_repository.dart` (singletons in `repositories.dart`). **Don't** scatter Supabase calls in widgets.
- Auth-gated: `lib/router/app_router.dart` redirects to `/login` when signed out. Bottom-tab shell (Home/Forums/Seforim/Search/Articles) + drill-down `Forums → category → subforum → thread`. **Thread detail lives inside the Forums branch** (not a root modal) so the bottom bar stays visible and a half-written reply survives a tab switch.
- Schema/RLS managed via Supabase migrations (apply via MCP `apply_migration`). RLS = public read, owner-only write. Counters maintained by triggers.
- **Seforim tab** = in-app Sefaria texts browser. Read-only via Sefaria's public HTTP API through `lib/data/seforim_repository.dart` (singleton). Browse `/api/index` tree → book TOC (`/api/shape`, chapter vs Talmud daf) → reader (`/api/v3/texts`, he+en). "Copy to reply" queues a source in `seforim_clipboard.dart`; the thread reply bar shows an Insert chip. Drafts persist via `composer_draft_store.dart`. We build our own UI (do NOT copy Sefaria's GPL code); attribute sources; "Sefaria" name/logo are trademarked so the tab is "Seforim". See `SEFORIM_PLAN.md`.
- Design bar: clean white forum app, indigo accent, clear threaded replies. See `memory` and `LAUNCH.md`.

## Demo logins (seeded)
`philo@demo.lilmod.app` / `Lilmod2026!` (also shaul@, leib@).

## What still needs the user (see LAUNCH.md)
Google OAuth credentials, email-confirm toggle, Apple Developer account + Sign in with Apple, app icon, privacy policy.

## Commands
- `flutter run` / `flutter run -d chrome`
- `flutter analyze` (keep clean), `flutter test`
