import 'dart:convert';
import 'dart:io';

import 'package:lint_benchmark/src/agents/record.dart';
import 'package:lint_benchmark/src/agents/report.dart';
import 'package:lint_benchmark/src/report.dart';

/// Renders `results/agents/runs.jsonl` into the README section between the
/// agents markers, and `results/agents/changes.jsonl` between the changes
/// markers. With `--check` it only verifies that both are current.
void main(List<String> args) {
  final check = args.contains('--check');
  final readme = File('../README.md');
  final current = readme.readAsStringSync();
  var updated = current;
  for (final (marker, path) in [
    ('agents', 'results/agents/runs.jsonl'),
    ('changes', 'results/agents/changes.jsonl'),
  ]) {
    final runs = _load(File(path));
    updated = replaceBetweenMarkers(
      updated,
      runs.isEmpty ? 'No runs recorded yet.\n' : renderAgentsReport(runs),
      marker: marker,
    );
  }
  if (check) {
    if (updated != current) {
      stderr.writeln(
        'README agents section is stale; run dart run bin/agents_report.dart',
      );
      exitCode = 1;
    }
    return;
  }
  readme.writeAsStringSync(updated);
}

List<RunRecord> _load(File file) => [
  for (final line in file.existsSync() ? file.readAsLinesSync() : <String>[])
    if (line.isNotEmpty)
      RunRecord.fromJson(jsonDecode(line) as Map<String, Object?>),
];
