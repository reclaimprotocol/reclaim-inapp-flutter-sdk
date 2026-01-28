import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  FfiGenerator(
    // Required. Output path for the generated bindings.
    output: Output(
      dartFile: packageRoot.resolve('lib/src/common/libreclaim/libreclaim.g.dart'),
      preamble: '''// ignore_for_file: type=lint, unused_element''',
    ),
    // Optional. Where to look for header files.
    headers: Headers(entryPoints: [packageRoot.resolve('src/libreclaim.h')]),
    // Optional. What functions to generate bindings for.
    functions: Functions.includeAll,
  ).generate();
}
