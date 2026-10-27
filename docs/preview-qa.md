# FlutterLens Public Preview QA

FlutterLens is a DevTools extension, not a standalone launcher yet. AI editing and `flutterlens .` are deliberately deferred beyond the v0.1 preview.

## Automated gates

1. Run `bash ./tool/check.sh` after resolving workspace dependencies as described in the README.
2. Build with `dart run devtools_extensions build_and_copy --source=. --dest=extension/devtools` from `packages/flutterlens`.
3. Validate with `dart run devtools_extensions validate --package=.`.
4. Confirm GitHub Actions passes on the PR and on `main` after merge.

## Manual connected-app smoke test

1. Launch `examples/showcase_app` in debug mode, open DevTools, and enable FlutterLens.
2. Confirm live connection metadata and widget tree; expand/collapse, search, select, and open source with an IDE listening. Select the **Live inspector QA** control card or a **Widget Atlas** product card so the selection is anchored to known showcase source.
3. Toggle **Compact sample layout** in the showcase and confirm the selected sample's real width and constraints change in the Inspector. Refresh or hot reload; stale selection must not crash the view.
4. Open Workspace → Performance; click **Rebuild sample** repeatedly and **Animate repaint** in the showcase. Confirm real frame timing and rebuild hotspots; enable repaint tracking and animate again to verify repaint activity.
5. Click **Report framework error** twice in the showcase and inspect Errors. Look for `FlutterLens QA: expected framework error`. Verify grouping, occurrence count, filtering, source link when known, and incident-report copying.
6. In Errors, verify the exception-pause menu shows the current debugger setting. Switch between Ignore, Unhandled, and All; confirm DevTools reflects the same active-isolate mode. To exercise `PauseException`, choose **Unhandled** or **All**, then explicitly click **Throw uncaught async** in the showcase. **This intentionally throws an uncaught error and may pause the target app**; resume through DevTools. Restore the original setting afterward.
7. Disconnect/reconnect to a **new debug session**, then choose a widget using the app-side Inspector selection mode and confirm FlutterLens receives its selection. Hot restart and refresh; ensure the controls do not claim a stale pause mode. This specifically checks VM Service listener rebinding.
8. Resize DevTools below 1250 logical pixels, then to a narrow mobile-style width. Use Tree / Workspace / Inspector tabs and confirm all panels remain reachable without negative widths or rendering exceptions.

## Recording release evidence

For each item above, record **Pass**, **Fail**, or **Not run**, with Flutter/Dart versions, platform, DevTools version, and screenshots or logs for failures. Do not call the v0.1 release validated until all required checks have passed against a real running application. Widget tests and CI alone cannot prove the embedded DevTools-to-application connection.

Quick commands from the repository root:

```bash
flutter pub get
bash ./tool/check.sh
cd packages/flutterlens
dart run devtools_extensions build_and_copy --source=. --dest=extension/devtools
dart run devtools_extensions validate --package=.
cd ../../examples/showcase_app
flutter run
```

The controls are deliberately in the showcase app, not FlutterLens itself. **Report framework error** uses `FlutterError.reportError`; **Throw uncaught async** is a separate, potentially debugger-pausing action.

## Known limitations

- Errors are live and retained in memory only (at most 200 events); FlutterLens is not crash-reporting storage.
- Pause mode applies to the current main isolate and can be changed concurrently by another debugger. Refresh to query the VM again.
- Some Inspector layout fields and source locations are unavailable for some widgets. FlutterLens does not invent missing runtime data.
- The preview has no AI file edits, command-line launcher, automatic source backup/rollback, or production telemetry.
