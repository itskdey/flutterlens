# FlutterLens Public Preview QA

FlutterLens is a DevTools extension, not a standalone launcher yet. AI editing and `flutterlens .` are deliberately deferred beyond the v0.1 preview.

## Automated gates

1. Run `./tool/check.sh` after fetching each package's dependencies as described in the README.
2. Build with `dart run devtools_extensions build_and_copy --source=. --dest=extension/devtools` from `packages/flutterlens`.
3. Validate with `dart run devtools_extensions validate --package=.`.
4. Confirm GitHub Actions passes on the PR and on `main` after merge.

## Manual connected-app smoke test

1. Launch `examples/showcase_app` in debug mode, open DevTools, and enable FlutterLens.
2. Confirm live connection metadata and widget tree; expand/collapse, search, select, and open source with an IDE listening.
3. Change a selected widget and confirm the Inspector reflects real properties and layout; refresh or hot reload and confirm stale selection does not crash the view.
4. Open Workspace → Performance; confirm frame timing, rebuild hotspots, and opt-in repaint tracking while interacting with the showcase.
5. Trigger a Flutter framework error and inspect Errors. Verify grouping, filtering, source link when known, and report copying.
6. In Errors, verify the exception-pause menu shows the current debugger setting. Switch between Ignore, Unhandled, and All; confirm DevTools reflects the same active-isolate mode. Restore the original setting afterward.
7. Disconnect/reconnect and hot restart; confirm the controls do not incorrectly claim a stale pause mode. Refresh after hot restart.
8. Resize DevTools below 1250 logical pixels, then to a narrow mobile-style width. Use Tree / Workspace / Inspector tabs and confirm all panels remain reachable without negative widths or rendering exceptions.

## Known limitations

- Errors are live and retained in memory only (at most 200 events); FlutterLens is not crash-reporting storage.
- Pause mode applies to the current main isolate and can be changed concurrently by another debugger. Refresh to query the VM again.
- Some Inspector layout fields and source locations are unavailable for some widgets. FlutterLens does not invent missing runtime data.
- The preview has no AI file edits, command-line launcher, automatic source backup/rollback, or production telemetry.
