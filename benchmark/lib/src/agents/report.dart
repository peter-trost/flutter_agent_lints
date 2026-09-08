import 'package:lint_benchmark/src/agents/record.dart';
import 'package:lint_benchmark/src/agents/similarity.dart';

/// Renders the README tables of the agent benchmark.
String renderAgentsReport(List<RunRecord> runs) {
  final configs = runs.map((r) => r.config).toSet().toList()..sort();
  final tasks = runs.map((r) => r.task).toSet().toList()..sort();
  final models = runs.map((r) => r.model).toSet().toList()..sort();
  final buffer = StringBuffer()
    ..writeln(
      '${runs.length} runs of ${models.join(', ')} over ${tasks.length} '
      'tasks (${tasks.join(', ')}). Hidden tests are run after the agent '
      'stops; strict issues are diagnostics of the result under the full '
      'flutter_agent_lints options, whatever the run used; consistency is '
      'the mean pairwise token similarity of the solutions to one task.',
    )
    ..writeln()
    ..writeln(
      '| Option set | Runs | Hidden tests passed | All tests passed | '
      'Turns | Time | Strict issues left | Ignores added |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final config in configs) {
    final of = runs.where((r) => r.config == config).toList();
    final passed = of.fold(0, (n, r) => n + r.testsPassed);
    final total = of.fold(0, (n, r) => n + r.testsTotal);
    final allPassed = of.where((r) => r.testsPassed == r.testsTotal).length;
    final ignores = of.fold(0, (n, r) => n + r.ignores);
    buffer.writeln(
      '| $config | ${of.length} | ${_percent(passed, total)} | '
      '$allPassed of ${of.length} | ${_mean(of, (r) => r.numTurns)} | '
      '${_mean(of, (r) => r.durationMs / 60000)} min | '
      '${_mean(of, (r) => r.fullIssues)} | $ignores |',
    );
  }

  buffer
    ..writeln()
    ..writeln('| Task | Option set | Consistency | Lines | Tests passed |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final task in tasks) {
    for (final config in configs) {
      final of = runs
          .where((r) => r.task == task && r.config == config)
          .toList();
      if (of.isEmpty) {
        continue;
      }
      final consistency = meanPairwiseSimilarity(
        of.map((r) => r.source).toList(),
      );
      final passed = of.fold(0, (n, r) => n + r.testsPassed);
      final total = of.fold(0, (n, r) => n + r.testsTotal);
      buffer.writeln(
        '| $task | $config | ${consistency?.toStringAsFixed(2) ?? 'n/a'} | '
        '${_mean(of, (r) => r.loc)} | ${_percent(passed, total)} |',
      );
    }
  }

  for (final config in configs) {
    final mentions = <String, int>{};
    for (final run in runs.where((r) => r.config == config)) {
      for (final entry in run.ruleMentions.entries) {
        mentions.update(
          entry.key,
          (n) => n + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    final rules = mentions.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    if (rules.isEmpty) {
      continue;
    }
    buffer
      ..writeln()
      ..writeln(
        'Diagnostics the agents ran into most under $config '
        '(occurrences in analyzer output they read):',
      )
      ..writeln()
      ..writeln('| Rule | Occurrences |')
      ..writeln('| --- | --- |');
    for (final rule in rules.take(10)) {
      buffer.writeln('| ${rule.key} | ${rule.value} |');
    }
  }
  return buffer.toString();
}

String _percent(int part, int whole) =>
    whole == 0 ? 'n/a' : '${(part / whole * 100).toStringAsFixed(1)}%';

String _mean(List<RunRecord> runs, num Function(RunRecord) value) {
  if (runs.isEmpty) {
    return 'n/a';
  }
  final sum = runs.fold<num>(0, (n, r) => n + value(r));
  return (sum / runs.length).toStringAsFixed(1);
}
