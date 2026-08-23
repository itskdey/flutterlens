# FlutterLens

> A modern visual inspector for Flutter.

FlutterLens is an open-source DevTools extension focused on a fast, visual workflow for understanding running Flutter applications.

> **Status:** v0.1 is in active development. Phase 2 proves the live VM Service and Flutter Inspector connection. The live widget tree lands next.

## Preview

Screenshot and demo assets will be added once the live inspector is connected. FlutterLens intentionally does not use fake widget-tree or runtime data for marketing screenshots.

## Why FlutterLens?

Flutter DevTools is powerful. FlutterLens explores a denser, design-tool-inspired workflow for inspecting widgets, source locations, layout information, rebuilds, and eventually reviewed AI-generated source patches.

## Current Features

- Real Flutter DevTools extension entry point
- DevTools-managed VM Service connection state
- Live Flutter/Dart runtime metadata
- Flutter Inspector reachability probe
- Dart Tooling Daemon connection status
- Desktop-first dark application shell
- Reusable theme tokens and connection indicator
- Responsive three-panel workspace shell
- Showcase Flutter app
- Unit and widget tests

## Planned MVP

- [x] DevTools extension bootstrap
- [x] Connection indicator
- [x] VM Service connection layer
- [x] Runtime information
- [x] Inspector service reachability
- [x] Developer-tool shell
- [x] Showcase app
- [ ] Live widget tree
- [ ] Widget selection and properties
- [ ] Source location
- [ ] Layout information
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
bash ./tool/check.sh
```

CI runs formatting, analysis, tests for every package, and `devtools_extensions validate` for the extension package.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Security

Please report security issues using the process in [SECURITY.md](SECURITY.md), not a public issue.

## License

FlutterLens is released under the [MIT License](LICENSE).
