import 'package:test/test.dart';

import '../tool/src/generate.dart';

const _options = '''
include: errors.yaml

linter:
  rules:
    prefer_single_quotes: true # reason
    prefer_double_quotes: false # reason
    avoid_print: true # reason
''';

void main() {
  group('enabledRuleNames', () {
    test('returns only the rules set to true', () {
      expect(enabledRuleNames(_options), {
        'prefer_single_quotes',
        'avoid_print',
      });
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

  group('errorsFile', () {
    test('promotes every name to error, sorted and deduplicated', () {
      final file = errorsFile(
        promoted: const ['unused_import', 'avoid_print', 'unused_import'],
      );
      expect(
        file,
        endsWith('''
analyzer:
  errors:
    avoid_print: error
    unused_import: error
'''),
      );
      expect(file, startsWith('# GENERATED CODE - DO NOT MODIFY BY HAND\n'));
      expect(file, isNot(contains('include:')));
    });

    test('includes the parent options file when asked', () {
      final file = errorsFile(
        promoted: const ['no_default_cases'],
        include: 'analysis_options.yaml',
      );
      expect(file, contains('\ninclude: analysis_options.yaml\n'));
      expect(file, endsWith('    no_default_cases: error\n'));
    });
  });

  group('missingRules', () {
    test('reports expected rules absent from the options file', () {
      final missing = missingRules(
        expected: const {'a', 'b', 'c'},
        listed: const {'a', 'c', 'd'},
      );
      expect(missing, const {'b'});
    });
  });
}
