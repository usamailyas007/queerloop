#!/usr/bin/env bash
set -euo pipefail

git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
flutter_sdk/bin/flutter config --enable-web
flutter_sdk/bin/flutter pub get
flutter_sdk/bin/flutter build web -t lib/main_admin.dart --dart-define-from-file=env/staging.json
