#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

check_dart_package() {
  local package="$1"
  echo "==> $package"
  (
    cd "$ROOT/$package"
    dart format --output=none --set-exit-if-changed .
    dart analyze
    dart test
  )
}

check_flutter_package() {
  local package="$1"
  echo "==> $package"
  (
    cd "$ROOT/$package"
    dart format --output=none --set-exit-if-changed .
    flutter analyze
    flutter test
  )
}

check_dart_package "packages/flutterlens_core"
check_flutter_package "packages/flutterlens_ui"

echo "==> packages/flutterlens (formatter diagnostic)"
(
  cd "$ROOT/packages/flutterlens"
  dart format .
  flutter analyze
  flutter test
)

check_flutter_package "examples/showcase_app"

echo "==> Final Phase 5 formatter diff"
git -C "$ROOT" diff -- packages/flutterlens/test/lens_widget_tree_controller_test.dart
exit 1
