import 'dart:io';

import 'src/diagnostics.dart';
import 'src/generate.dart';

/// Regenerates the `analyzer.errors` blocks in the shipped option files.
///
/// Every enabled lint rule and every analyzer diagnostic whose default
/// severity is not error is promoted to error. Pass `--check` to verify the
/// files are current without writing; exits with code 1 if they are not.
void main(List<String> args) {
  final check = args.contains('--check');
  final diagnostics = nonErrorDiagnosticNames();
  var stale = false;
  for (final (path, promoteDiagnostics) in [
    ('lib/analysis_options.yaml', true),
    ('lib/experimental.yaml', false),
  ]) {
    final file = File(path);
    final current = file.readAsStringSync();
    final generated = generateErrorsBlock(
      current,
      diagnostics: promoteDiagnostics ? diagnostics : const [],
    );
    if (generated == current) {
      continue;
    }
    if (check) {
      stderr.writeln(
        '$path is out of date; run `dart run tool/generate.dart`.',
      );
      stale = true;
    } else {
      file.writeAsStringSync(generated);
      stdout.writeln('updated $path');
    }
  }
  if (stale) {
    exitCode = 1;
  }
}
