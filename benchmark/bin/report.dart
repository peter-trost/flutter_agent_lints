import 'dart:convert';
import 'dart:io';

import 'package:lint_benchmark/src/report.dart';
import 'package:lint_benchmark/src/score.dart';

/// Renders `results/*.json` into the README section between the benchmark
/// markers. With `--check` it only verifies that the section is current.
void main(List<String> args) {
  final check = args.contains('--check');
  final scores = <String, List<CommitScore>>{};
  final repos = <String>[];
  var commits = 0;

  final files = Directory('results').listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    repos.add(json['repo']! as String);
    for (final commit
        in (json['commits']! as List<Object?>).cast<Map<String, Object?>>()) {
      commits++;
      final byOptionSet = commit['scores']! as Map<String, Object?>;
      for (final entry in byOptionSet.entries) {
        scores
            .putIfAbsent(entry.key, () => [])
            .add(CommitScore.fromJson(entry.value! as Map<String, Object?>));
      }
    }
  }

  final report = renderReport(
    scores.map((k, v) => MapEntry(k, aggregate(v))),
    repos: repos,
    commits: commits,
  );
  final readme = File('../README.md');
  final current = readme.readAsStringSync();
  final updated = replaceBetweenMarkers(current, report);
  if (check) {
    if (updated != current) {
      stderr.writeln(
        'README benchmark section is stale; run dart run bin/report.dart',
      );
      exitCode = 1;
    }
    return;
  }
  readme.writeAsStringSync(updated);
}
