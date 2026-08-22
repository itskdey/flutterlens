# Contributing to FlutterLens

Thanks for helping improve FlutterLens.

## Development principles

- Keep DevTools/VM Service calls out of widgets.
- Prefer typed FlutterLens models over raw protocol maps.
- Do not fake inspector/runtime values.
- Keep changes focused and testable.
- Avoid dependencies unless they clearly reduce complexity.

## Before opening a pull request

Run:

```bash
./tool/check.sh
```

Use descriptive commits such as `feat: add VM service connection layer` or `test: cover connection state transitions`.
