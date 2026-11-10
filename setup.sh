#!/usr/bin/env bash
# Creates the android/ and ios/ folders around the Safro source, then installs packages.
set -e
if ! command -v flutter >/dev/null; then echo "Install Flutter first: https://docs.flutter.dev/get-started/install"; exit 1; fi
mkdir -p .bak && cp -r lib pubspec.yaml test .bak/ 2>/dev/null || true
flutter create --org com.safro --project-name safro --platforms=android,ios .
rm -rf lib test && cp -r .bak/lib lib && cp -r .bak/test test && cp .bak/pubspec.yaml pubspec.yaml
rm -rf .bak
flutter pub get
echo
echo "Done. Next: follow README.md steps 2-4 (Firebase + Maps key), then flutter run."
