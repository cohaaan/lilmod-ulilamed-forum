# Context Map — Lilmod Ulilamed forum

This repo is organized into bounded contexts that mirror the data-layer repositories
under `lib/data/`. Each context owns its domain vocabulary in a `CONTEXT.md`.

These `CONTEXT.md` files are created lazily by `/domain-modeling` as terms and
decisions actually get resolved — only this map exists up front. If a context's
`CONTEXT.md` is missing, proceed silently (see `docs/agents/domain.md`).

| Context  | Glossary (CONTEXT.md)             | Owns                                                        | Primary code |
| -------- | --------------------------------- | ---------------------------------------------------------- | ------------ |
| Forum    | `docs/context/forum/CONTEXT.md`   | Threads, replies, likes, bookmarks, categories, subforums  | `lib/data/forum_repository.dart`, `lib/screens/forums/` |
| Auth     | `docs/context/auth/CONTEXT.md`    | Sign-in, sessions, demo logins, OAuth                       | `lib/data/auth_repository.dart`, `lib/screens/auth/` |
| Chavrusa | `docs/context/chavrusa/CONTEXT.md`| Directory, invite codes, access control                    | `lib/data/chavrusa_repository.dart`, `lib/data/chavrusa_invite_store.dart`, `lib/data/chavrusa_access.dart` |
| Seforim  | `docs/context/seforim/CONTEXT.md` | Sefaria texts browser (read-only), clipboard, drafts       | `lib/data/seforim_repository.dart`, `SEFORIM_PLAN.md` |

System-wide architectural decisions live in `docs/adr/`. Context-scoped decisions,
if any, live alongside that context's `CONTEXT.md`.
