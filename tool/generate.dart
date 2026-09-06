import 'dart:io';

import 'src/diagnostics.dart';
import 'src/generate.dart';

/// Regenerates the shipped errors files.
///
/// `lib/errors.yaml` promotes every rule enabled in `lib/analysis_options.yaml`
/// and every analyzer diagnostic whose default severity is not error;
/// `lib/experimental_errors.yaml` promotes the rules enabled in
/// `lib/experimental.yaml` on top of that. Pass `--check` to verify the files
/// are current without writing; exits with code 1 if they are not.
void main(List<String> args) {
  final check = args.contains('--check');
  var stale = false;
  for (final (source, target, include, withDiagnostics) in [
    ('lib/analysis_options.yaml', 'lib/errors.yaml', null, true),
    (
      'lib/experimental.yaml',
      'lib/experimental_errors.yaml',
      'analysis_options.yaml',
      false,
    ),
  ]) {
    final generated = errorsFile(
      promoted: {
        ...enabledRuleNames(File(source).readAsStringSync()),
        if (withDiagnostics) ...nonErrorDiagnosticNames(),
      },
      include: include,
    );
    final file = File(target);
    final current = file.existsSync() ? file.readAsStringSync() : null;
    if (generated == current) {
      continue;
    }
    if (check) {
      stderr.writeln(
        '$target is out of date; run `dart run tool/generate.dart`.',
      );
      stale = true;
    } else {
      file.writeAsStringSync(generated);
      stdout.writeln('wrote $target');
    }
  }
  if (stale) {
    exitCode = 1;
  }
}
