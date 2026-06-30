#!/usr/bin/env bash
# Builds Flutter web for Vercel (installs Flutter on Vercel's Linux builders).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter stable..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter config --no-analytics
  flutter precache --web
fi

# Share links: prefer explicit SITE_URL env var, then Vercel production URL.
if [[ -n "${SITE_URL:-}" ]]; then
  DEFINE_SITE_URL="$SITE_URL"
elif [[ -n "${VERCEL_PROJECT_PRODUCTION_URL:-}" ]]; then
  DEFINE_SITE_URL="https://${VERCEL_PROJECT_PRODUCTION_URL}"
elif [[ -n "${VERCEL_URL:-}" ]]; then
  DEFINE_SITE_URL="https://${VERCEL_URL}"
else
  DEFINE_SITE_URL="https://lilmod-ulilamed.vercel.app"
fi

echo "Building Flutter web (SITE_URL=$DEFINE_SITE_URL)..."

flutter pub get
flutter build web --release --dart-define="SITE_URL=$DEFINE_SITE_URL"
