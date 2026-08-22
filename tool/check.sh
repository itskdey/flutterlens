#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES=(
  "packages/flutterlens_core"
  "packages/flutterlens_ui"
  "packages/flutterlens"
  "examples/showcase_app"
)

for package in "${PACKAGES[@]}"; do
  echo "==> $package"
  (
    cd "$ROOT/$package"
    dart format --output=none --set-exit-if-changed .
    flutter analyze
    flutter test
  )
done
