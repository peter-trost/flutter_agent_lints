import 'dart:io';

import 'src/skill_rules.dart';

/// Verifies the shipped skill still describes the ruleset it teaches.
///
/// Every rule the skill names must be enabled in `lib/analysis_options.yaml`.
/// A rule that is turned off or removed there but still described in the
/// skill teaches consumers to write for a rule that no longer applies.
void main() {
  final options = File('lib/analysis_options.yaml').readAsStringSync();
  final skillFiles =
      Directory('skills')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var failed = false;
  for (final file in skillFiles) {
    final stale = staleRules(skill: file.readAsStringSync(), options: options);
    if (stale.isEmpty) {
      continue;
    }
    failed = true;
    stderr.writeln('${file.path}: describes rules that are not enabled:');
    for (final rule in stale) {
      stderr.writeln('  $rule');
    }
  }

  if (failed) {
    stderr.writeln(
      '\nEnable the rule again, or update the skill to match the ruleset.',
    );
    exitCode = 1;
  } else {
    stdout.writeln('${skillFiles.length} skill files match the ruleset');
  }
}
