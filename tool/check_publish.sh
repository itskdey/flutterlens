#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# The extension must ship its compiled entry point; source alone will not be
# discoverable by DevTools in a published package.
test -s "$ROOT/packages/flutterlens/extension/devtools/build/index.html"

for package in flutterlens_core flutterlens_ui flutterlens; do
  echo "==> publish dry run: $package"
  test -s "$ROOT/packages/$package/README.md"
  test -s "$ROOT/packages/$package/LICENSE"
  (
    cd "$ROOT/packages/$package"
    dart pub publish --dry-run
  )
done
