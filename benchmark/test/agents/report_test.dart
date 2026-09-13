import 'package:lint_benchmark/src/agents/record.dart';
import 'package:lint_benchmark/src/agents/report.dart';
import 'package:test/test.dart';

RunRecord _run(
  String config,
  int rep, {
  int passed = 8,
  int turns = 10,
  int fullIssues = 3,
  String source = 'int a = 1;',
  int? changedLines,
}) => RunRecord(
  task: 'countdown',
  config: config,
  rep: rep,
  model: 'opus',
  subtype: 'success',
  numTurns: turns,
  durationMs: 120000,
  costUsd: 0.5,
  inputTokens: 1000,
  outputTokens: 2000,
  testsPassed: passed,
  testsTotal: 8,
  analyzeIssues: 0,
  fullIssues: fullIssues,
  fullByRule: const {'prefer_final_locals': 3},
  ignores: 0,
  optionsModified: false,
  ruleMentions: const {'unawaited_futures': 2},
  loc: 80,
  source: source,
  changedLines: changedLines,
);

void main() {
  final runs = [
    _run('flutter_lints', 0, turns: 8),
    _run('flutter_lints', 1, passed: 4, turns: 12, source: 'void f() {}'),
    _run('selected', 0, turns: 14, fullIssues: 1),
    _run('selected', 1, turns: 16, fullIssues: 1),
  ];

  group('renderAgentsReport', () {
    final report = renderAgentsReport(runs);

    test('summarises each option set', () {
      expect(
        report,
        contains('| flutter_lints | 2 | 75.0% | 1 of 2 | 10.0 | 2.0 min |'),
      );
      expect(
        report,
        contains('| selected | 2 | 100.0% | 2 of 2 | 15.0 | 2.0 min |'),
      );
    });

    test('reports consistency per task and option set', () {
      expect(report, contains('| countdown | flutter_lints | 0.0'));
      expect(report, contains('| countdown | selected | 1.0'));
    });

    test('lists the rules the agents ran into most', () {
      expect(report, contains('| unawaited_futures | 4 |'));
    });

    test('has no changed-lines column for runs that started empty', () {
      expect(report, isNot(contains('Changed lines')));
    });
  });

  group('renderAgentsReport for change runs', () {
    final report = renderAgentsReport([
      _run('flutter_lints@flutter_lints', 0, changedLines: 20),
      _run('flutter_lints@flutter_lints', 1, changedLines: 30),
    ]);

    test('names the seed arm and averages the lines changed', () {
      expect(report, contains('seeded'));
      expect(report, contains('| Changed lines |'));
      expect(
        report,
        contains(
          '| flutter_lints@flutter_lints | 2 | 100.0% | 2 of 2 | 10.0 | '
          '2.0 min | 3.0 | 0 | 25.0 |',
        ),
      );
    });
  });

  group('RunRecord json', () {
    test('round-trips', () {
      final record = _run('selected', 3);
      expect(RunRecord.fromJson(record.toJson()).toJson(), record.toJson());
    });

    test('keeps the changed-lines count of a seeded run', () {
      final record = _run('selected@selected', 3, changedLines: 12);
      expect(RunRecord.fromJson(record.toJson()).changedLines, 12);
    });

    test('reads an old record without one', () {
      final json = _run('selected', 3).toJson()..remove('changedLines');
      expect(RunRecord.fromJson(json).changedLines, isNull);
    });
  });
}
