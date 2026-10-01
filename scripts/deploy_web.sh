#!/usr/bin/env bash
# Build the admin web panel locally and deploy the output to Vercel via the CLI.
#
#   scripts/deploy_web.sh            → preview deploy (staging API)
#   scripts/deploy_web.sh --prod     → production deploy (prod API)
#
# The API is HTTPS, but the admin panel still calls it via a same-origin
# /api/* proxy (not directly) to avoid depending on backend CORS config.
# The rewrites below proxy /api/* to the API host, and the app is built
# with BASE_URL=/api.
set -euo pipefail

cd "$(dirname "$0")/.."

PROD_FLAG=""
ENV_FILE="env/staging_web.json"
API_HOST="https://api-test.queerloopplus.com"
if [[ "${1:-}" == "--prod" ]]; then
  PROD_FLAG="--prod"
  ENV_FILE="env/prod_web.json"
  API_HOST="https://api.queerloopplus.com"
fi

echo "▸ flutter build web (admin entrypoint, BASE_URL=/api, env=$ENV_FILE)"
flutter build web --release \
  -t lib/main_admin.dart \
  --dart-define-from-file="$ENV_FILE"

echo "▸ writing build/web/vercel.json (proxy → $API_HOST + SPA fallback)"
cat > build/web/vercel.json <<JSON
{
  "rewrites": [
    { "source": "/api/:path*", "destination": "$API_HOST/:path*" },
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
JSON

echo "▸ deploying to Vercel (project: queerloop-admin)"
cd build/web
vercel deploy --yes $PROD_FLAG
