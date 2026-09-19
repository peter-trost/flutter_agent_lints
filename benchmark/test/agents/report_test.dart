import 'package:lint_benchmark/src/agents/record.dart';
import 'package:lint_benchmark/src/agents/report.dart';
import 'package:test/test.dart';

RunRecord _run(
  String config,
  int rep, {
  int passed = 8,
  int total = 8,
  int turns = 10,
  int ignores = 0,
  int? changedLines,
}) => RunRecord(
  task: 'countdown',
  config: config,
  rep: rep,
  model: 'opus',
  subtype: 'success',
  numTurns: turns,
  tokens: 100000,
  testsPassed: passed,
  testsTotal: total,
  ignores: ignores,
  ruleMentions: const {'unawaited_futures': 2},
  loc: 80,
  changedLines: changedLines,
);

void main() {
  group('renderAgentsReport', () {
    final report = renderAgentsReport([
      _run('flutter_lints', 0, turns: 8),
      _run('flutter_lints', 1, passed: 4, turns: 12),
      _run('flutter_agent_lints+skill', 0, turns: 14),
      _run('flutter_agent_lints+skill', 1, turns: 16),
    ]);

    test('has one row per option set', () {
      expect(
        report,
        contains('| flutter_lints | 2 | 1 of 2 | 10.0 | 100k | 80 | 2.0 |'),
      );
      expect(
        report,
        contains(
          '| flutter_agent_lints+skill | 2 | 2 of 2 | 15.0 | 100k | 80 | 2.0 |',
        ),
      );
    });

    test('shows no changed-lines or ignores column when there is nothing', () {
      expect(report, isNot(contains('Changed lines')));
      expect(report, isNot(contains('Ignores')));
    });

    test('adds a changed-lines column for seeded runs', () {
      final seeded = renderAgentsReport([
        _run('flutter_lints@flutter_lints', 0, changedLines: 20),
        _run('flutter_lints@flutter_lints', 1, changedLines: 30),
      ]);
      expect(seeded, contains('| Changed lines |'));
      expect(seeded, contains('| 80 | 2.0 | 25.0 |'));
    });

    test('a run whose hidden tests did not run is not a pass', () {
      final broken = renderAgentsReport([
        _run('flutter_lints', 0, passed: 0, total: 0),
      ]);
      expect(broken, contains('| flutter_lints | 1 | 0 of 1 |'));
    });

    test('adds an ignores column when any run added one', () {
      final cheated = renderAgentsReport([
        _run('flutter_lints', 0, ignores: 1),
      ]);
      expect(cheated, contains('| Ignores |'));
      expect(cheated, contains('| 1 |'));
    });
  });

  group('RunRecord json', () {
    test('round-trips', () {
      final record = _run('flutter_lints', 3, changedLines: 12);
      expect(RunRecord.fromJson(record.toJson()).toJson(), record.toJson());
    });

    test('reads a record without a changed-lines count', () {
      final json = _run('flutter_lints', 3).toJson()..remove('changedLines');
      expect(RunRecord.fromJson(json).changedLines, isNull);
    });
  });
}
