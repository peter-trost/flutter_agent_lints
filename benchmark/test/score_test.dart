import 'package:lint_benchmark/src/diagnostics.dart';
import 'package:lint_benchmark/src/diff.dart';
import 'package:lint_benchmark/src/score.dart';
import 'package:test/test.dart';

Diagnostic _d(
  String code,
  int line, {
  String type = 'LINT',
  String file = 'a',
}) => Diagnostic(code: code, type: type, file: file, line: line);

void main() {
  final changes = {
    'a': const ChangedLines(before: {5, 6}, after: {5, 6, 7}),
    'b': const ChangedLines(before: {1}, after: {1}),
  };
  const lineCounts = {'a': 100, 'b': 50};

  group('scoreCommit', () {
    test('a diagnostic on a fixed line that the fix removes is a hit', () {
      final score = scoreCommit(
        changes: changes,
        before: [_d('avoid_print', 5)],
        after: const [],
        lineCounts: lineCounts,
      );
      expect(score.fixLines, 3);
      expect(score.hitLines, 1);
      expect(score.hitsByRule, {'avoid_print': 1});
    });

    test('a diagnostic that survives on the fixed lines is not a hit', () {
      final score = scoreCommit(
        changes: changes,
        before: [_d('avoid_print', 5)],
        after: [_d('avoid_print', 7)],
        lineCounts: lineCounts,
      );
      expect(score.hitLines, 0);
      expect(score.hitsByRule, isEmpty);
    });

    test('diagnostics off the fixed lines only feed the density', () {
      final score = scoreCommit(
        changes: changes,
        before: [_d('avoid_print', 40), _d('prefer_final_locals', 40)],
        after: const [],
        lineCounts: lineCounts,
      );
      expect(score.hitLines, 0);
      expect(score.diagnosticLines, 1);
      expect(score.totalLines, 150);
    });

    test('lines per rule count distinct lines anywhere in the files', () {
      final score = scoreCommit(
        changes: changes,
        before: [
          _d('avoid_print', 5),
          _d('avoid_print', 40),
          _d('avoid_print', 40),
          _d('avoid_print', 1, file: 'b'),
        ],
        after: const [],
        lineCounts: lineCounts,
      );
      expect(score.linesByRule, {'avoid_print': 3});
    });

    test('compile errors are ignored on both sides', () {
      final score = scoreCommit(
        changes: changes,
        before: [_d('undefined_function', 5, type: 'COMPILE_TIME_ERROR')],
        after: const [],
        lineCounts: lineCounts,
      );
      expect(score.hitLines, 0);
      expect(score.diagnosticLines, 0);
      expect(score.linesByRule, isEmpty);
    });

    test('two rules on one fixed line count one line and two rule hits', () {
      final score = scoreCommit(
        changes: changes,
        before: [_d('avoid_print', 5), _d('prefer_final_locals', 5)],
        after: const [],
        lineCounts: lineCounts,
      );
      expect(score.hitLines, 1);
      expect(score.hitsByRule, {'avoid_print': 1, 'prefer_final_locals': 1});
    });

    test('files are matched by path', () {
      final score = scoreCommit(
        changes: changes,
        before: [
          _d('avoid_print', 1, file: 'b'),
          _d('avoid_print', 1),
        ],
        after: const [],
        lineCounts: lineCounts,
      );
      expect(score.hitLines, 1);
    });
  });

  group('aggregate', () {
    test('sums the scores and counts flagged commits', () {
      final total = aggregate([
        const CommitScore(
          fixLines: 10,
          hitLines: 2,
          diagnosticLines: 5,
          totalLines: 500,
          hitsByRule: {'avoid_print': 2},
          linesByRule: {'avoid_print': 4, 'prefer_final_locals': 1},
        ),
        const CommitScore(
          fixLines: 4,
          hitLines: 0,
          diagnosticLines: 5,
          totalLines: 500,
          hitsByRule: {},
          linesByRule: {'avoid_print': 5},
        ),
      ]);
      expect(total.commits, 2);
      expect(total.commitsFlagged, 1);
      expect(total.fixLines, 14);
      expect(total.hitLines, 2);
      expect(total.hitsByRule, {'avoid_print': 2});
      expect(total.commitsByRule, {'avoid_print': 1});
      expect(total.linesByRule, {'avoid_print': 9, 'prefer_final_locals': 1});
    });

    test('lift compares the hit rate on fixed lines with the density', () {
      final total = aggregate([
        const CommitScore(
          fixLines: 10,
          hitLines: 2,
          diagnosticLines: 10,
          totalLines: 1000,
          hitsByRule: {'avoid_print': 1},
          linesByRule: {'avoid_print': 2},
        ),
      ]);
      expect(total.lift, 20.0);
      expect(total.ruleLift('avoid_print'), 50.0);
    });

    test('lift is zero without diagnostics rather than a division error', () {
      final total = aggregate([
        const CommitScore(
          fixLines: 10,
          hitLines: 0,
          diagnosticLines: 0,
          totalLines: 1000,
          hitsByRule: {},
          linesByRule: {},
        ),
      ]);
      expect(total.lift, 0);
      expect(total.ruleLift('avoid_print'), 0);
    });
  });

  group('CommitScore json', () {
    test('round-trips', () {
      const score = CommitScore(
        fixLines: 1,
        hitLines: 1,
        diagnosticLines: 2,
        totalLines: 3,
        hitsByRule: {'x': 1},
        linesByRule: {'x': 2, 'y': 1},
      );
      expect(CommitScore.fromJson(score.toJson()).toJson(), score.toJson());
    });
  });
}
