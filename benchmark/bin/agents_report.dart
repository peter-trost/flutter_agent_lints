import 'dart:convert';
import 'dart:io';

import 'package:lint_benchmark/src/agents/record.dart';
import 'package:lint_benchmark/src/agents/report.dart';
import 'package:lint_benchmark/src/report.dart';

/// Renders `results/agents/runs.jsonl` into the README section between the
/// agents markers. With `--check` it only verifies that the section is
/// current.
void main(List<String> args) {
  final check = args.contains('--check');
  final file = File('results/agents/runs.jsonl');
  final runs = [
    for (final line in file.existsSync() ? file.readAsLinesSync() : <String>[])
      if (line.isNotEmpty)
        RunRecord.fromJson(jsonDecode(line) as Map<String, Object?>),
  ];
  final readme = File('../README.md');
  final current = readme.readAsStringSync();
  final updated = replaceBetweenMarkers(
    current,
    runs.isEmpty ? 'No runs recorded yet.\n' : renderAgentsReport(runs),
    marker: 'agents',
  );
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
