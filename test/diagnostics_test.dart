import 'package:test/test.dart';

import '../tool/src/diagnostics.dart';

void main() {
  group('nonErrorDiagnosticNames', () {
    test('includes warning and info codes but not error codes', () {
      final names = nonErrorDiagnosticNames();
      expect(
        names,
        containsAll(<String>['todo', 'unused_import', 'dead_code']),
      );
      expect(names, isNot(contains('undefined_function')));
    });
  });
}
