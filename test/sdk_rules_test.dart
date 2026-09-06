import 'package:test/test.dart';

import '../tool/src/sdk_rules.dart';

const _rulesJson = '''
[
  {"name": "avoid_print", "state": "stable"},
  {"name": "avoid_as", "state": "removed"},
  {"name": "no_default_cases", "state": "experimental"},
  {"name": "one_member_abstracts", "state": "deprecated"}
]
''';

void main() {
  group('ruleNamesWithState', () {
    test('selects the rules in the given state', () {
      expect(ruleNamesWithState(_rulesJson, 'stable'), {'avoid_print'});
      expect(ruleNamesWithState(_rulesJson, 'experimental'), {
        'no_default_cases',
      });
    });
  });

  group('allRuleNames', () {
    test('returns every rule regardless of state', () {
      expect(allRuleNames(_rulesJson), hasLength(4));
    });
  });

  group('unusableRulesFromAnalyzerOutput', () {
    test('extracts rules the analyzer reports deprecated or removed', () {
      const output = '''
WARNING|STATIC_WARNING|DEPRECATED_LINT|/x/analysis_options.yaml|4|7|22|The lint rule 'unnecessary_await_in_return' is deprecated and shouldn't be enabled.
WARNING|STATIC_WARNING|REMOVED_LINT|/x/analysis_options.yaml|5|7|8|'avoid_as' was removed in Dart '2.12.0'
INFO|LINT|AVOID_PRINT|/x/bin/main.dart|3|3|5|Don't invoke 'print' in production code.
''';
      expect(unusableRulesFromAnalyzerOutput(output), {
        'unnecessary_await_in_return',
        'avoid_as',
      });
    });
  });
}
