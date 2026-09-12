import 'package:test/test.dart';

import '../tool/src/skill_rules.dart';

const _options = '''
linter:
  rules:
    avoid_print: true # A reason.
    cascade_invocations: true # Another reason.
    public_member_api_docs: false # Off on purpose.
''';

void main() {
  group('mentionedRules', () {
    test('reads backticked rule names', () {
      expect(
        mentionedRules('Use `avoid_print` and `cascade_invocations` here.'),
        {'avoid_print', 'cascade_invocations'},
      );
    });

    test('ignores prose and short identifiers', () {
      expect(mentionedRules('a `var` and `x` and plain avoid_print'), isEmpty);
    });
  });

  group('staleRules', () {
    test('is empty when every named rule is enabled', () {
      expect(
        staleRules(skill: 'Use `avoid_print`.', options: _options),
        isEmpty,
      );
    });

    test('flags a rule the ruleset disables', () {
      expect(
        staleRules(skill: 'Write `public_member_api_docs`.', options: _options),
        ['public_member_api_docs'],
      );
    });

    test('ignores names the ruleset does not know', () {
      expect(
        staleRules(
          skill: 'See `analysis_options` and `strict_raw_type`.',
          options: _options,
        ),
        isEmpty,
      );
    });
  });
}
