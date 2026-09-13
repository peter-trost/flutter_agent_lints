import 'package:lint_benchmark/src/report.dart';
import 'package:test/test.dart';

void main() {
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
