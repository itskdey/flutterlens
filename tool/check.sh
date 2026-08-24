#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

check_dart_package() {
  local package="$1"
  echo "==> $package"
  (
    cd "$ROOT/$package"
    dart format .
    dart analyze
    dart test
  )
}

check_flutter_package() {
  local package="$1"
  echo "==> $package"
  (
    cd "$ROOT/$package"
    dart format .
    flutter analyze
    flutter test
  )
}

check_dart_package "packages/flutterlens_core"
check_flutter_package "packages/flutterlens_ui"
check_flutter_package "packages/flutterlens"
check_flutter_package "examples/showcase_app"

git -C "$ROOT" diff --exit-code
