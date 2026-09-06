import 'package:test/test.dart';

import '../tool/src/sdk_version.dart';

void main() {
  group('sdkLowerBound', () {
    test('extracts the lower bound of a caret constraint', () {
      expect(sdkLowerBound('^3.13.0'), '3.13.0');
    });

    test('extracts the lower bound of a range constraint', () {
      expect(sdkLowerBound('>=3.13.0 <4.0.0'), '3.13.0');
    });
  });

  group('bundledAnalyzerVersion', () {
    test('strips the -dev suffix the SDK repository carries', () {
      expect(
        bundledAnalyzerVersion('name: analyzer\nversion: 14.1.0-dev\n'),
        '14.1.0',
      );
    });

    test('keeps a plain version as is', () {
      expect(bundledAnalyzerVersion('version: 14.1.0\n'), '14.1.0');
    });
  });
}
