import 'dart:convert';
import 'dart:io';

import 'src/skill_samples.dart';

/// Analyzes every Dart sample in the shipped skill against the ruleset the
/// skill teaches, so a sample cannot tell an agent to write code the
/// analyzer would reject.
///
/// Samples are written into a scratch directory inside `example/`, which
/// already resolves Flutter and includes the package's own options.
///
/// Diagnostics that only exist because a sample is read in isolation, such
/// as an illustrative field nothing reads, are not failures: the samples are
/// fragments by design.
Future<void> main() async {
  final scratch = Directory('example/lib/skill_samples');
  if (scratch.existsSync()) {
    scratch.deleteSync(recursive: true);
  }
  scratch.createSync(recursive: true);

  var count = 0;
  for (final file
      in Directory('skills')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))) {
    final name = file.uri.pathSegments.last;
    for (final sample in samplesIn(
      file: name,
      markdown: file.readAsStringSync(),
    )) {
      final needsFlutter =
          name.contains('flutter') && !sample.code.contains('import ');
      File('${scratch.path}/${sample.name}').writeAsStringSync(
        needsFlutter
            ? "import 'package:flutter/material.dart';\n\n${sample.code}"
            : sample.code,
      );
      count++;
    }
  }

  final result = await Process.run('dart', [
    'analyze',
    '--format=json',
    scratch.path,
  ]);
  final out = result.stdout as String;
  scratch.deleteSync(recursive: true);

  final start = out.indexOf('{');
  if (start < 0) {
    stderr.writeln('the analyzer produced no report:\n${result.stderr}');
    exitCode = 1;
    return;
  }
  final report = jsonDecode(out.substring(start)) as Map<String, Object?>;
  final problems = (report['diagnostics']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .where((d) => !_isolationOnly.contains(d['code']))
      .toList();

  if (problems.isEmpty) {
    stdout.writeln('$count skill samples analyze clean');
    return;
  }
  stderr.writeln('skill samples the ruleset rejects:');
  for (final problem in problems) {
    final location = problem['location']! as Map<String, Object?>;
    final line =
        (location['range']! as Map<String, Object?>)['start']!
            as Map<String, Object?>;
    stderr.writeln(
      '  ${location['file']}:${line['line']} '
      '${problem['problemMessage']} (${problem['code']})',
    );
  }
  exitCode = 1;
}

/// Diagnostics a fragment triggers only because nothing else references it.
const _isolationOnly = [
  'unused_field',
  'unused_local_variable',
  'unused_element',
];
