#!/usr/bin/env bash
# Runs on Vercel when the project is deployed from git.
# The API is plain http://, so it is proxied through /api/* (see vercel.json
# "rewrites") and the app is built with BASE_URL=/api.
set -euo pipefail

git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
flutter_sdk/bin/flutter config --enable-web
flutter_sdk/bin/flutter pub get
flutter_sdk/bin/flutter build web --release \
  -t lib/main_admin.dart \
  --dart-define-from-file=env/staging_web.json
