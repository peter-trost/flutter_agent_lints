import 'package:lint_benchmark/src/options.dart';
import 'package:test/test.dart';

const _files = {
  'package:flutter_lints/flutter.yaml': '''
include: package:lints/recommended.yaml
linter:
  rules:
    - avoid_print
''',
  'package:lints/recommended.yaml': '''
include: package:lints/core.yaml
linter:
  rules:
    - annotate_overrides
''',
  'package:lints/core.yaml': '''
linter:
  rules:
    - avoid_print
    - curly_braces_in_flow_control_structures
''',
};

void main() {
  group('flattenOptions', () {
    test('merges the rules of the whole include chain into one file', () {
      final flat = flattenOptions(
        'package:flutter_lints/flutter.yaml',
        read: (uri) => _files[uri]!,
      );
      expect(flat, '''
# Flattened from package:flutter_lints/flutter.yaml by lint_benchmark.
linter:
  rules:
    - annotate_overrides
    - avoid_print
    - curly_braces_in_flow_control_structures
''');
    });
  });
}
