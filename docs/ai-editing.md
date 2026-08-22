# Future AI Editing Design

AI editing is intentionally out of scope for FlutterLens v0.1.

The planned safety boundary is patch-based:

```text
selected widget → source location → read narrow source context → generate patch
→ validate patch → show diff → explicit approval → backup → apply
→ dart format → dart analyze → hot reload
```

The editor must not blindly replace complete files. Failed validation should leave the developer with the original source or a reversible patch operation. Undo, redo, and restore-original are first-class future requirements.
