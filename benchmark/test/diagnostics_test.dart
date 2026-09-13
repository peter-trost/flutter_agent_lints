import 'package:lint_benchmark/src/diagnostics.dart';
import 'package:test/test.dart';

const _json = '''
{"version":1,"diagnostics":[
  {"code":"avoid_print","severity":"ERROR","type":"LINT",
   "location":{"file":"/repo/app/lib/a.dart",
     "range":{"start":{"offset":46,"line":2,"column":26},
              "end":{"offset":51,"line":2,"column":31}}},
   "problemMessage":"Don't invoke 'print' in production code."},
  {"code":"undefined_function","severity":"ERROR","type":"COMPILE_TIME_ERROR",
   "location":{"file":"/repo/app/lib/a.dart",
     "range":{"start":{"offset":0,"line":7,"column":1},
              "end":{"offset":3,"line":7,"column":4}}},
   "problemMessage":"x"}
]}
''';

void main() {
  group('parseAnalyzeJson', () {
    test('keeps code, type, file and start line of each diagnostic', () {
      final diagnostics = parseAnalyzeJson(_json, packageRoot: '/repo/app');
      expect(diagnostics, hasLength(2));
      expect(diagnostics.first.code, 'avoid_print');
      expect(diagnostics.first.type, 'LINT');
      expect(diagnostics.first.file, 'lib/a.dart');
      expect(diagnostics.first.line, 2);
    });
  });

  group('Diagnostic.countsForOptions', () {
    Diagnostic of(String type) =>
        Diagnostic(code: 'c', type: type, file: 'f', line: 1);

    test('lints and analyzer warnings are attributable to the options', () {
      expect(of('LINT').countsForOptions, isTrue);
      expect(of('STATIC_WARNING').countsForOptions, isTrue);
      expect(of('HINT').countsForOptions, isTrue);
    });

    test('compile and syntax errors fire under any options', () {
      expect(of('COMPILE_TIME_ERROR').countsForOptions, isFalse);
      expect(of('SYNTACTIC_ERROR').countsForOptions, isFalse);
    });
  });
}
