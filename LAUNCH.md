# Lilmod Ulilamed — Launch & Setup Guide

This app is a **real, working forum** backed by Supabase (Postgres + Auth + RLS).
Threads, replies, likes, bookmarks, and search all read/write to the live
database. This document covers the parts that require **your** accounts to go
fully live, plus how to run and test.

---

## 1. Backend (already provisioned)

- **Supabase project:** `lilmod-ulilamed` (ref `lxcbaortmbhjsthycdkt`), region `us-east-1`, free tier.
- **URL:** `https://lxcbaortmbhjsthycdkt.supabase.co`
- **Publishable key:** in `lib/config/supabase_config.dart` (safe to ship — RLS protects everything).
- **Schema:** profiles, categories, subforums, threads, posts (replies), thread_likes, post_likes, bookmarks.
- **Security:** Row-Level Security on every table — anyone can read; users can only create/edit/delete **their own** content. Verified end-to-end.
- **Triggers:** auto-create profile on signup; maintain reply/like counts and last-activity.

### Demo accounts (already seeded, ready to sign in)
| Email | Password | Name |
|---|---|---|
| `philo@demo.lilmod.app` | `Lilmod2026!` | Philo |
| `shaul@demo.lilmod.app` | `Lilmod2026!` | שאו מרום עיניכם |
| `leib@demo.lilmod.app`  | `Lilmod2026!` | Leib Shachar |

Sign in with any of these to immediately browse, post threads, and reply.

---

## 2. Things YOU need to do to go fully live

### A. Email signups (5 min) — pick one
New email/password signups currently require **email confirmation** (Supabase default), so a brand-new account can't post until the link is clicked.
- **To allow instant signups:** Supabase Dashboard → **Authentication → Providers → Email** → turn **"Confirm email" OFF**. (Fine for a forum that also uses Google.)
- Or leave it on and let users confirm via the email they receive.

### B. Google Sign-In (the auth you chose) — ~20 min
The button and deep-link plumbing are built. To make it function:
1. **Google Cloud Console** → create an OAuth 2.0 **Web** client.
   - Authorized redirect URI: `https://lxcbaortmbhjsthycdkt.supabase.co/auth/v1/callback`
2. **Supabase Dashboard → Authentication → Providers → Google** → enable, paste the **Client ID** and **Client Secret**.
3. **Supabase Dashboard → Authentication → URL Configuration → Redirect URLs** → add:
   `app.lilmodulilamed://login-callback`
   (This scheme is already registered in iOS `Info.plist` and `AndroidManifest.xml`.)

### C. iOS App Store submission — needs an Apple Developer account ($99/yr)
1. **Apple Developer Program** membership.
2. In **Xcode** → Runner target → Signing & Capabilities → select your Team (bundle id is `com.lilmodulilamed.lilmodUlilamed`).
3. **Add "Sign in with Apple"** — Apple **requires** it because the app offers Google sign-in. (Capability + a Supabase Apple provider; the auth UI is structured to add an Apple button next to Google.)
4. **App icon** — provide a 1024×1024 PNG; generate with `flutter_launcher_icons` (see §4).
5. **Privacy policy URL** (required) + fill App Privacy questionnaire (this app collects: email, display name, user content).
6. Screenshots, App Store description, then submit for review.

### D. Android (Play Store) — when ready
Apply id is `com.lilmodulilamed.lilmod_ulilamed`. Needs a Play Console account ($25 one-time), signing key, icon, privacy policy.

---

## 3. Run it locally

```bash
flutter pub get
flutter run            # pick a device/simulator
# or
flutter run -d chrome  # web
```

Sign in with a demo account above. Try: open a subforum → **New thread** → post;
open a thread → **reply**, **like**, **bookmark**, **share link**.

---

## 4. App icon (optional helper)

Add to `pubspec.yaml` dev_dependencies and run:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1
flutter_launcher_icons:
  image_path: "assets/icon/icon.png"   # a 1024x1024 png you provide
  android: true
  ios: true
```
```bash
dart run flutter_launcher_icons
```

---

## 5. Architecture (for developers)

- `lib/config/` — Supabase connection.
- `lib/models/` — `Profile`, `Category`/`Subforum`, `Thread`, `Post`, `ArticleItem`.
- `lib/data/` — `auth_repository.dart`, `forum_repository.dart` (all DB access), `repositories.dart` (singletons), `articles_data.dart`.
- `lib/router/app_router.dart` — go_router with auth-gated redirect + bottom-tab shell + forum drill-down + thread/account routes.
- `lib/screens/` — home, forums → category → subforum → thread detail, compose, search, articles, account, auth/login.
- `lib/widgets/` — reusable UI (post card, forum rows, avatar, soft card, async view, nav bar).
- Forum hierarchy: **Forums → category → subforum → thread → replies**, every level deep-linkable.

---

## 6. Web deployment (Vercel)

The Flutter web app deploys to **Vercel** (`vercel.json` + `scripts/vercel-build.sh`).

**Live URL:** https://lilmod-ulilamed.vercel.app

### Deploy from your machine
```bash
# One-shot (build + deploy)
bash scripts/deploy-vercel.sh

# Or step by step
flutter build web --release --dart-define=SITE_URL=https://lilmod-ulilamed.vercel.app
npx vercel build --prod
npx vercel deploy --prebuilt --prod
```

Share links use `SITE_URL` (Vercel env var in production, or `--dart-define` locally).

### Custom domain
1. Vercel Dashboard → **lilmod-ulilamed** → **Settings → Domains** → add your domain.
2. Point DNS at Vercel (CNAME to `cname.vercel-dns.com`, or A record `76.76.21.21` for apex).
3. Update Vercel env **`SITE_URL`** to `https://yourdomain.com` and redeploy.
4. Supabase Dashboard → **Authentication → URL Configuration**:
   - **Site URL:** `https://yourdomain.com`
   - **Redirect URLs:** add `https://yourdomain.com/**` (keep `app.lilmodulilamed://login-callback` for mobile).
