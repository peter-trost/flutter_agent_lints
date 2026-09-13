import 'package:lint_benchmark/src/agents/similarity.dart';
import 'package:test/test.dart';

void main() {
  group('similarity', () {
    test('identical sources score one', () {
      expect(similarity('int a = 1;', 'int a = 1;'), 1.0);
    });

    test('unrelated sources score near zero', () {
      expect(similarity('int a = 1;', 'void f() {}'), lessThan(0.2));
    });

    test('a small edit scores high', () {
      const a = 'final x = compute(a, b); return x + 1;';
      const b = 'final y = compute(a, b); return y + 1;';
      expect(similarity(a, b), closeTo(0.85, 0.05));
    });

    test('whitespace and comments do not count', () {
      expect(similarity('int a=1;', 'int   a = 1; // c'), 1.0);
    });
  });

  group('meanPairwiseSimilarity', () {
    test('averages every pair', () {
      expect(
        meanPairwiseSimilarity(['a b', 'a b', 'c d']),
        closeTo(1 / 3, 1e-9),
      );
    });

    test('fewer than two sources have no pairs', () {
      expect(meanPairwiseSimilarity(['a']), isNull);
    });
  });
}
