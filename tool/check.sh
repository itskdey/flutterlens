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

check_flutter_package_diagnostic() {
  local package="$1"
  echo "==> $package (formatter diagnostic)"
  (
    cd "$ROOT/$package"
    dart format .
    flutter analyze || true
    flutter test || true
  )
}

check_dart_package "packages/flutterlens_core"
check_flutter_package "packages/flutterlens_ui"
check_flutter_package_diagnostic "packages/flutterlens"
check_flutter_package "examples/showcase_app"

echo "==> Dart 3.47 formatter diff"
git -C "$ROOT" diff -- \
  packages/flutterlens/lib/src/devtools/devtools_widget_inspector_source.dart \
  packages/flutterlens/lib/src/devtools/inspector_diagnostics_mapper.dart

# Diagnostic runs are intentionally red until the exact formatter output is
# committed and this script is restored to strict mode.
exit 1
