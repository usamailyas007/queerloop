#!/usr/bin/env bash
# Build the consumer app (lib/main.dart) for TestFlight. ALWAYS uses
# env/prod.json — there is no staging/debug variant of this script on
# purpose, so a TestFlight build can never accidentally ship with the
# wrong backend.
#
# This also fixes a real footgun: ios/Flutter/Generated.xcconfig caches
# whatever --dart-define values were used in the LAST `flutter` command,
# and Xcode's own "Product > Archive" reads directly from that cached
# file. If you archive from Xcode without running this first, you get
# whatever environment happened to be cached, not necessarily prod.
#
# Usage:
#   scripts/build_ios_testflight.sh
#
# Produces build/ios/ipa/*.ipa, ready to upload via Transporter or
# Xcode Organizer. Requires valid signing/provisioning already set up
# in Xcode for the Runner target.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "▸ flutter build ipa (consumer app, env/prod.json — this also refreshes"
echo "  ios/Flutter/Generated.xcconfig so Xcode archives use the same values)"
flutter build ipa --release \
  -t lib/main.dart \
  --dart-define-from-file=env/prod.json

echo "▸ done — build/ios/ipa/*.ipa is ready for TestFlight upload"
