import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/features/shell/flutterlens_app.dart';

void main() {
  runApp(
    const DevToolsExtension(
      child: FlutterLensApp(),
    ),
  );
}
