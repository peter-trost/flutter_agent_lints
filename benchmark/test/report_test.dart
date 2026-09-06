import 'package:lint_benchmark/src/report.dart';
import 'package:lint_benchmark/src/score.dart';
import 'package:test/test.dart';

void main() {
  final agentLints = aggregate([
    const CommitScore(
      fixLines: 100,
      hitLines: 12,
      diagnosticLines: 40,
      totalLines: 2000,
      hitsByRule: {'avoid_print': 8, 'unawaited_futures': 4},
      linesByRule: {
        'avoid_print': 20,
        'unawaited_futures': 4,
        'lines_longer_than_80_chars': 30,
      },
    ),
  ]);
  final flutterLints = aggregate([
    const CommitScore(
      fixLines: 100,
      hitLines: 3,
      diagnosticLines: 5,
      totalLines: 2000,
      hitsByRule: {'avoid_print': 3},
      linesByRule: {'avoid_print': 5},
    ),
  ]);

  group('renderReport', () {
    final report = renderReport(
      {'flutter_lints': flutterLints, 'flutter_agent_lints': agentLints},
      repos: const ['localsend'],
      commits: 1,
    );

    test('has one row per option set with rate and lift', () {
      expect(
        report,
        contains(
          '| flutter_agent_lints | 1 of 1 | 12 of 100 (12.0%) | 2.0% | 6.0x |',
        ),
      );
      expect(
        report,
        contains('| flutter_lints | 1 of 1 | 3 of 100 (3.0%) | 0.3% | 12.0x |'),
      );
    });

    test('lists the rules that flagged the most fixed lines with lift', () {
      expect(report, contains('| avoid_print | 8 | 1 | 8.0x |'));
      expect(report, contains('| unawaited_futures | 4 | 1 | 20.0x |'));
      expect(report, isNot(contains('lines_longer_than_80_chars')));
    });
  });

  group('replaceBetweenMarkers', () {
    test('replaces only the text between the markers', () {
      const text = 'a\n<!-- benchmark -->\nold\n<!-- /benchmark -->\nb\n';
      expect(
        replaceBetweenMarkers(text, 'new\n'),
        'a\n<!-- benchmark -->\nnew\n<!-- /benchmark -->\nb\n',
      );
    });

    test('fails loudly when a marker is missing', () {
      expect(() => replaceBetweenMarkers('a', 'new'), throwsStateError);
    });
  });
}
