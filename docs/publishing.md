# FlutterLens v0.1 publishing plan

**Status:** preparation only. The packages are not yet available on pub.dev and no GitHub release tag has been created.

The Dart pub workspace contains three publishable packages and one unpublished showcase app:

1. `flutterlens_core` — pure Dart models and interfaces
2. `flutterlens_ui` — reusable Flutter inspection widgets (depends on core)
3. `flutterlens` — the DevTools extension, including its compiled web assets (depends on core and UI)

Workspace resolution uses local source packages during development even though the package manifests declare hosted version constraints. Pub consumers will resolve the published versions instead. For an initial release the dependent packages **must** be published in the order above.

## Quality gate

From the repository root:

```bash
flutter pub get
bash ./tool/check.sh
cd packages/flutterlens
dart run devtools_extensions build_and_copy --source=. --dest=extension/devtools
dart run devtools_extensions validate --package=.
cd ../..
bash ./tool/check_publish.sh
```

Inspect the output of every `dart pub publish --dry-run` carefully. In particular, the `flutterlens` package must include `extension/devtools/config.yaml` and `extension/devtools/build/index.html` plus the supporting Flutter web assets. The `.pubignore` rules deliberately exclude transient root build/cache files **without excluding the nested DevTools extension build**.

## Release gate (manual)

1. Complete the [connected-app smoke tests](preview-qa.md) with a real Flutter debug session, including error capture, selection sync, and debugger pause-mode changes.
2. Confirm GitHub Actions passes on the release commit.
3. Check the three package names and versions on pub.dev and establish publishing authorization for the intended publisher.
4. Review the dry-run contents and package metadata, then publish core, UI, and extension in that order with `dart pub publish` from each package directory. Do not publish a package whose hosted dependency has not appeared on pub.dev yet.
5. Only after publication and an installation test from a **separate app** should a v0.1 preview GitHub release/tag be created.

Publishing to pub.dev is permanent for the published versions. It is intentionally **not automated by the CI workflow** and should not be initiated solely because a PR passes tests.
