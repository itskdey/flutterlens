# Architecture

FlutterLens uses a strict dependency direction:

```text
Flutter DevTools APIs
        ↓
DevTools adapters (flutterlens)
        ↓
Contracts/models (flutterlens_core)
        ↓
Application state (flutterlens)
        ↓
Presentation (flutterlens_ui)
```

`flutterlens_core` does not depend on DevTools. `flutterlens_ui` depends on core models but not on VM Service or DevTools globals. This keeps inspector logic mockable and allows a future standalone shell to reuse the same models and UI.

## Future inspector boundary

The live inspector will be introduced behind a `FlutterInspector` contract in core. The concrete implementation will live in `packages/flutterlens/lib/src/devtools/` and translate Flutter diagnostic/VM Service objects into immutable FlutterLens models.
