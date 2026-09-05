import 'package:test/test.dart';

import '../tool/src/generate.dart';

const _options = '''
analyzer:
  errors:
    # BEGIN GENERATED
    # END GENERATED

linter:
  rules:
    prefer_single_quotes: true # reason
    prefer_double_quotes: false # reason
    avoid_print: true # reason
''';

void main() {
  group('generateErrorsBlock', () {
    test(
      'promotes every enabled lint rule to error, sorted, between markers',
      () {
        final output = generateErrorsBlock(_options, diagnostics: const []);
        expect(output, '''
analyzer:
  errors:
    # BEGIN GENERATED
    avoid_print: error
    prefer_single_quotes: error
    # END GENERATED

linter:
  rules:
    prefer_single_quotes: true # reason
    prefer_double_quotes: false # reason
    avoid_print: true # reason
''');
      },
    );

    test(
      'merges analyzer diagnostics into the same sorted block, deduplicated',
      () {
        final output = generateErrorsBlock(
          _options,
          diagnostics: const ['unused_import', 'todo', 'unused_import'],
        );
        expect(
          output,
          contains('''
    # BEGIN GENERATED
    avoid_print: error
    prefer_single_quotes: error
    todo: error
    unused_import: error
    # END GENERATED
'''),
        );
      },
    );

    test('is idempotent', () {
      final once = generateErrorsBlock(_options, diagnostics: const ['todo']);
      final twice = generateErrorsBlock(once, diagnostics: const ['todo']);
      expect(twice, once);
    });

    test('throws when the markers are missing', () {
      expect(
        () => generateErrorsBlock(
          'linter:\n  rules: {}\n',
          diagnostics: const [],
        ),
        throwsFormatException,
      );
    });
  });

  group('missingRules', () {
    test('reports required rules absent from the options file', () {
      final missing = missingRules(
        required: const {'a', 'b', 'c'},
        listed: const {'a', 'c', 'd'},
      );
      expect(missing, const {'b'});
    });
  });

  group('listedRuleNames', () {
    test('returns every rule key whether enabled or disabled', () {
      expect(listedRuleNames(_options), {
        'prefer_single_quotes',
        'prefer_double_quotes',
        'avoid_print',
      });
    });
  });
}
