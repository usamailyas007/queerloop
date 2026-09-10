#!/usr/bin/env bash
# Build the admin web panel locally and deploy the output to Vercel via the CLI.
#
#   scripts/deploy_web.sh            → preview deploy
#   scripts/deploy_web.sh --prod     → production deploy
#
# The API lives on plain http://, so a browser on the https Vercel domain
# cannot call it directly (mixed content + CORS). The rewrites below proxy
# /api/* to the API host, and the app is built with BASE_URL=/api.
set -euo pipefail

cd "$(dirname "$0")/.."

PROD_FLAG=""
[[ "${1:-}" == "--prod" ]] && PROD_FLAG="--prod"

echo "▸ flutter build web (admin entrypoint, BASE_URL=/api)"
flutter build web --release \
  -t lib/main_admin.dart \
  --dart-define-from-file=env/staging_web.json

echo "▸ writing build/web/vercel.json (proxy + SPA fallback)"
cat > build/web/vercel.json <<'JSON'
{
  "rewrites": [
    { "source": "/api/:path*", "destination": "http://3.208.100.236:3001/:path*" },
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
JSON

echo "▸ deploying to Vercel (project: queerloop-admin)"
cd build/web
vercel deploy --yes $PROD_FLAG
