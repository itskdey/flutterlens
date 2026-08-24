# FlutterLens

> A modern visual inspector for Flutter.

FlutterLens is an open-source DevTools extension focused on a fast, visual workflow for understanding running Flutter applications.

> **Status:** v0.1 is in active development. FlutterLens can connect through DevTools, inspect runtime metadata, retrieve the real live widget tree, and inspect selected-widget properties, source locations, and layout information from the running app.

## Preview

Screenshot and demo assets will be added once the inspector experience is polished. FlutterLens intentionally does not use fake widget-tree or runtime data for marketing screenshots.

## Why FlutterLens?

Flutter DevTools is powerful. FlutterLens explores a denser, design-tool-inspired workflow for inspecting widgets, source locations, layout information, rebuilds, and eventually reviewed AI-generated source patches.

## Current Features

- Real Flutter DevTools extension entry point
- DevTools-managed VM Service connection state
- Flutter and Dart runtime metadata
- Flutter Inspector service detection
- Real live widget tree from the running application
- Lazy widget child loading with expand/collapse
- Local tree selection
- Selected-widget diagnostic properties
- Real layout size and box constraints when exposed by Flutter Inspector
- Parent-data offset, flex factor/fit, and render-object summary when available
- Source file, line, and column when supplied by Flutter Inspector
- Inspector object-group cleanup on refresh, selection changes, and dispose
- Desktop-first dark application shell
- Showcase Flutter app

## Roadmap

- [x] DevTools extension bootstrap
- [x] Connection indicator
- [x] Runtime and Inspector connection
- [x] Live widget tree
- [x] Expand / collapse
- [x] Widget selection state
- [x] Widget properties
- [x] Layout information
- [ ] Widget search
- [ ] Inspector selection mode
- [ ] Rebuild tracking
- [ ] Performance summary
- [ ] AI-assisted patches
- [ ] Standalone CLI

## Requirements

FlutterLens currently targets:

- Flutter 3.27.1 or newer
- Dart 3.6 or newer
- Debug-mode Flutter applications
- Flutter DevTools extensions

The minimum versions follow the current `devtools_extensions` package requirements.

## Getting Started

Fetch dependencies for each package:

```bash
cd packages/flutterlens_core && dart pub get
cd ../flutterlens_ui && flutter pub get
cd ../flutterlens && flutter pub get
cd ../../examples/showcase_app && flutter pub get
```

Build the extension into its discovery directory:

```bash
cd packages/flutterlens
dart run devtools_extensions validate --package=.
dart run devtools_extensions build_and_copy --source=. --dest=extension/devtools
```

Run the showcase app:

```bash
cd examples/showcase_app
flutter run
```

Open DevTools for the running app and enable **FlutterLens** when prompted. The showcase app declares FlutterLens as a development dependency so DevTools can discover the extension.

## Inspector Notes

FlutterLens uses the Flutter Inspector service extensions already exposed by the running debug application. It does not open a second VM Service connection.

The live tree uses a dedicated Inspector object group. Refreshing the tree disposes the previous object group before requesting new diagnostic node IDs, which is important because Inspector IDs can become stale after hot reloads and restarts.

Selected-widget inspection uses a separate short-lived object group. Each new selection disposes the previous inspection group before FlutterLens requests `getProperties` and, when available, `getLayoutExplorerNode`. This keeps runtime references scoped to the currently displayed inspector state.

Layout fields are shown only when Flutter exposes them for the selected diagnostic node. Some widgets do not produce a box-layout node, so size, constraints, offset, flex, or render-object information may legitimately be absent.

For the current MVP, direct Inspector queries are disabled while the main isolate is paused at a breakpoint. DevTools itself can fall back to evaluation-based Inspector calls in this case; FlutterLens will add an equivalent fallback only if it can be done cleanly without coupling the UI to DevTools internals.

## Architecture

```text
Flutter / DevTools APIs
        ↓
FlutterLens adapters
        ↓
FlutterLens core models
        ↓
Application state
        ↓
FlutterLens UI
```

```text
packages/
├── flutterlens/       # DevTools extension + DevTools-specific adapters
├── flutterlens_core/  # Tooling-neutral models, contracts, logging
└── flutterlens_ui/    # Reusable desktop developer-tool UI

examples/
└── showcase_app/      # Deliberately inspectable Flutter app
```

The UI never owns VM Service calls. DevTools-specific APIs stay in the extension package behind FlutterLens interfaces.

## Development

Run the repository checks with:

```bash
./tool/check.sh
```

Or run `dart format .`, `flutter analyze`, and `flutter test` inside each Flutter package.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Security

Please report security issues using the process in [SECURITY.md](SECURITY.md), not a public issue.

## License

FlutterLens is released under the [MIT License](LICENSE).
