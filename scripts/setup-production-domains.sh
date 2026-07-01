#!/usr/bin/env bash
# Attach forum + chavrusas subdomains on Vercel and push Supabase auth redirect URLs.
#
# Prerequisites:
#   - npx vercel login   (already done if `vercel whoami` works)
#   - supabase login     (one-time browser flow, or SUPABASE_ACCESS_TOKEN env var)
#   - DNS at your registrar: CNAME forums → value from `vercel domains verify forums.lilmodulilamed.com`
#
# Usage:
#   bash scripts/setup-production-domains.sh
#   bash scripts/setup-production-domains.sh --deploy   # also set SITE_URL and production deploy
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="lilmod-ulilamed"
SUPABASE_REF="lxcbaortmbhjsthycdkt"
FORUMS_HOST="forums.lilmodulilamed.com"
SITE_URL="https://${FORUMS_HOST}"

vercel_cmd() { npx vercel "$@"; }
supabase_cmd() { command -v supabase >/dev/null && supabase "$@" || npx supabase "$@"; }

echo "==> Vercel: attach ${FORUMS_HOST} to ${PROJECT}"
vercel_cmd domains add "${FORUMS_HOST}" "${PROJECT}" 2>/dev/null || true

echo ""
echo "==> Vercel: DNS check for ${FORUMS_HOST}"
vercel_cmd domains verify "${FORUMS_HOST}" || true

echo ""
echo "==> Vercel: production SITE_URL=${SITE_URL}"
if vercel_cmd env ls production 2>/dev/null | grep -q '^ SITE_URL'; then
  vercel_cmd env rm SITE_URL production --yes
fi
printf '%s' "${SITE_URL}" | vercel_cmd env add SITE_URL production

if [[ "${1:-}" == "--deploy" ]]; then
  echo ""
  echo "==> Vercel: production deploy (SITE_URL baked into Flutter build)"
  vercel_cmd --prod
fi

echo ""
echo "==> Supabase: push auth redirect URLs from supabase/config.toml"
if ! supabase_cmd projects list >/dev/null 2>&1; then
  echo "    Run: supabase login"
  echo "    Then re-run this script."
  exit 0
fi

if [[ ! -f supabase/.temp/project-ref ]]; then
  supabase_cmd link --project-ref "${SUPABASE_REF}" --yes
fi

supabase_cmd config push --yes

echo ""
echo "Done."
echo "  Forum URL (after DNS):  ${SITE_URL}"
echo "  Chavrusas URL:          https://chavrusas.lilmodulilamed.com"
echo "  If ${FORUMS_HOST} is misconfigured, add the CNAME shown above at your registrar."
