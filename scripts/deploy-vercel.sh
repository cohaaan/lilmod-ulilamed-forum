#!/usr/bin/env bash
# Local helper: build Flutter web and deploy to Vercel via CLI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SITE_URL="${SITE_URL:-}"
if [[ -z "$SITE_URL" && -n "${VERCEL_PROJECT_PRODUCTION_URL:-}" ]]; then
  SITE_URL="https://${VERCEL_PROJECT_PRODUCTION_URL}"
fi

BUILD_ARGS=(flutter build web --release)
if [[ -n "$SITE_URL" ]]; then
  BUILD_ARGS+=(--dart-define="SITE_URL=$SITE_URL")
  echo "Building with SITE_URL=$SITE_URL"
else
  echo "Building with default SITE_URL (set SITE_URL=https://your-domain.com to override)"
fi

flutter pub get
"${BUILD_ARGS[@]}"

echo "Deploying to Vercel..."
npx vercel deploy --prebuilt --prod "$@"
