# FlutterLens

A visual Flutter DevTools extension for inspecting a running debug-mode Flutter app. Inspect the real widget tree, properties and layout; search and select widgets; open source in a connected IDE; and monitor rebuilds, frame performance, and runtime errors.

This package provides the `flutterlens` DevTools extension. It relies on DevTools' existing VM Service connection rather than opening its own.

You can also import `package:flutterlens/flutterlens.dart` for the shared core models and reusable UI widgets.

## Installation (once published)

Add `flutterlens` to your application's `dev_dependencies` using the published version, run `flutter pub get`, and start your app in debug mode. Open DevTools and enable FlutterLens in the Extensions dialog when prompted.

For now, contributors can build and run the extension directly from the [source repository](https://github.com/itskdey/flutterlens#readme).

## Limitations

- Requires a connected debug-mode Flutter app with Inspector service extensions.
- AI-assisted editing and the standalone CLI are not included in v0.1.
- Diagnostic events are live and in-memory only; no historical crash reporting.

See the [full documentation](https://github.com/itskdey/flutterlens) and [preview QA checklist](https://github.com/itskdey/flutterlens/blob/main/docs/preview-qa.md). Licensed under MIT.
