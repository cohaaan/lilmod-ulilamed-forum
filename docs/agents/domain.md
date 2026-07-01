# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

This repo is configured as **multi-context**: `CONTEXT-MAP.md` at the root points at one `CONTEXT.md` per bounded context.

## Before exploring, read these

- **`CONTEXT-MAP.md`** at the repo root — it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`** — system-wide architectural decisions. Read ADRs that touch the area you're about to work in.
- Context-scoped ADRs, if present, live alongside the context's `CONTEXT.md` (see `CONTEXT-MAP.md` for the path).

If any of these files don't exist yet, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## File structure

Multi-context (this repo). Contexts map to the data-layer repositories under `lib/data/`:

```
/
├── CONTEXT-MAP.md                     ← index of contexts (created)
├── docs/adr/                          ← system-wide decisions
└── docs/context/
    ├── forum/CONTEXT.md               ← threads, replies, likes, bookmarks
    ├── auth/CONTEXT.md                ← sign-in, sessions, demo logins
    ├── chavrusa/CONTEXT.md            ← directory, invite codes, access
    └── seforim/CONTEXT.md             ← Sefaria texts browser (read-only)
```

The per-context `CONTEXT.md` files are created lazily by `/domain-modeling`; only `CONTEXT-MAP.md` exists up front.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in the relevant `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 — but worth reopening because…_
