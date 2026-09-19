import 'package:lint_benchmark/src/agents/record.dart';

/// Renders one README table: a row per option set, over every task.
String renderAgentsReport(List<RunRecord> runs) {
  // The Flutter default first, as the baseline the other rows compare to.
  final configs = runs.map((r) => r.config).toSet().toList()
    ..sort((a, b) {
      final aBase = a.startsWith('flutter_lints') ? 0 : 1;
      final bBase = b.startsWith('flutter_lints') ? 0 : 1;
      return aBase != bBase ? aBase - bBase : a.compareTo(b);
    });
  final tasks = runs.map((r) => r.task).toSet().toList()..sort();
  final models = runs.map((r) => r.model).toSet().toList()..sort();
  final seeded = runs.any((r) => r.changedLines != null);
  final cheated = runs.any((r) => r.ignores > 0);
  final buffer = StringBuffer()
    ..writeln(
      '${runs.length} runs of ${models.join(', ')} over ${tasks.length} '
      'tasks (${tasks.join(', ')}). '
      '${seeded ? _seededIntro : ''}'
      'Hidden tests run after the agent stops; diagnostics read are '
      'analyzer diagnostics in output the agent saw during the run.',
    )
    ..writeln()
    ..writeln(
      '| Option set | Runs | All tests passed | Turns | Tokens | Lines | '
      'Diagnostics read |'
      '${seeded ? ' Changed lines |' : ''}'
      '${cheated ? ' Ignores |' : ''}',
    )
    ..writeln(
      '| --- | --- | --- | --- | --- | --- | --- |'
      '${seeded ? ' --- |' : ''}'
      '${cheated ? ' --- |' : ''}',
    );
  for (final config in configs) {
    final of = runs.where((r) => r.config == config).toList();
    // No visible test at all means the hidden tests did not run, which is
    // what a broken public API looks like: a failure, not a pass.
    final allPassed = of
        .where((r) => r.testsTotal > 0 && r.testsPassed == r.testsTotal)
        .length;
    buffer.writeln(
      '| $config | ${of.length} | $allPassed of ${of.length} | '
      '${_mean(of, (r) => r.numTurns)} | '
      '${(_meanValue(of, (r) => r.tokens) / 1000).round()}k | '
      '${_meanValue(of, (r) => r.loc).round()} | '
      '${_mean(of, (r) => r.diagnosticsRead)} |'
      '${seeded ? ' ${_mean(of, (r) => r.changedLines ?? 0)} |' : ''}'
      '${cheated ? ' ${of.fold(0, (n, r) => n + r.ignores)} |' : ''}',
    );
  }
  return buffer.toString();
}

const _seededIntro =
    'Each run starts from the code a recorded run of the arm after the @ '
    'produced and asks for one feature on top of it; changed lines are '
    'lines added or removed in the solution file. ';

double _meanValue(List<RunRecord> runs, num Function(RunRecord) value) =>
    runs.fold<num>(0, (n, r) => n + value(r)) / runs.length;

String _mean(List<RunRecord> runs, num Function(RunRecord) value) =>
    _meanValue(runs, value).toStringAsFixed(1);
