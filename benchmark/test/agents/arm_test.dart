import 'package:lint_benchmark/src/agents/arm.dart';
import 'package:test/test.dart';

void main() {
  group('Arm.parse', () {
    test('a bare option set has no skill and no seed', () {
      final arm = Arm.parse('flutter_lints');
      expect(arm.options, 'flutter_lints');
      expect(arm.withSkill, isFalse);
      expect(arm.seed, isNull);
    });

    test('a +skill suffix installs the skill, with or without a label', () {
      expect(Arm.parse('flutter_agent_lints+skill').withSkill, isTrue);
      final labelled = Arm.parse('flutter_agent_lints+skill-v2');
      expect(labelled.withSkill, isTrue);
      expect(labelled.options, 'flutter_agent_lints');
    });

    test('an @ names the arm whose output seeds the workdir', () {
      final arm = Arm.parse('flutter_lints@flutter_agent_lints+skill-v2');
      expect(arm.options, 'flutter_lints');
      expect(arm.withSkill, isFalse);
      expect(arm.seed, 'flutter_agent_lints+skill-v2');
    });
  });

  group('changedLines', () {
    test('counts lines added and removed between two sources', () {
      expect(changedLines('a\nb\nc\n', 'a\nb\nc\n'), 0);
      expect(changedLines('a\nb\n', 'a\nx\nb\ny\n'), 2);
      expect(changedLines('a\nb\nc\n', 'a\nc\n'), 1);
      expect(changedLines('a\nb\n', 'c\nd\n'), 4);
    });
  });
}
