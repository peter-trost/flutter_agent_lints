import 'package:test/test.dart';

import '../tool/src/bump.dart';

const _sdk = '^3.13.0';

void main() {
  group('decideBump', () {
    test(
      'is none when only comments changed and the SDK bound is the same',
      () {
        final bump = decideBump(
          previousShipped: {'a.yaml': 'linter:\n  rules:\n    x: true # old\n'},
          currentShipped: {'a.yaml': 'linter:\n  rules:\n    x: true # new\n'},
          previousSdk: _sdk,
          currentSdk: _sdk,
        );
        expect(bump, Bump.none);
      },
    );

    test('is major when a shipped file changes semantically', () {
      final bump = decideBump(
        previousShipped: {'a.yaml': 'linter:\n  rules:\n    x: true\n'},
        currentShipped: {'a.yaml': 'linter:\n  rules:\n    x: false\n'},
        previousSdk: _sdk,
        currentSdk: _sdk,
      );
      expect(bump, Bump.major);
    });

    test('is major when a shipped file is added or removed', () {
      final bump = decideBump(
        previousShipped: {'a.yaml': 'linter:\n  rules:\n    x: true\n'},
        currentShipped: {
          'a.yaml': 'linter:\n  rules:\n    x: true\n',
          'b.yaml': 'linter:\n  rules:\n    y: true\n',
        },
        previousSdk: _sdk,
        currentSdk: _sdk,
      );
      expect(bump, Bump.major);
    });

    test('is minor when a shipped skill file changed or appeared', () {
      const rules = {'a.yaml': 'linter:\n  rules:\n    x: true\n'};
      expect(
        decideBump(
          previousShipped: rules,
          currentShipped: rules,
          previousSdk: _sdk,
          currentSdk: _sdk,
          currentSkill: const {'skills/s/SKILL.md': '# Strict Dart\n'},
        ),
        Bump.minor,
      );
      expect(
        decideBump(
          previousShipped: rules,
          currentShipped: rules,
          previousSdk: _sdk,
          currentSdk: _sdk,
          previousSkill: const {'skills/s/SKILL.md': '# Strict Dart\n'},
          currentSkill: const {'skills/s/SKILL.md': '# Strict Dart\n\nMore.\n'},
        ),
        Bump.minor,
      );
    });

    test('a rule change stays major even when the skill changed too', () {
      final bump = decideBump(
        previousShipped: {'a.yaml': 'linter:\n  rules:\n    x: true\n'},
        currentShipped: {'a.yaml': 'linter:\n  rules:\n    x: false\n'},
        previousSdk: _sdk,
        currentSdk: _sdk,
        currentSkill: const {'skills/s/SKILL.md': '# Strict Dart\n'},
      );
      expect(bump, Bump.major);
    });

    test('is minor when only the SDK bound moved', () {
      final bump = decideBump(
        previousShipped: {'a.yaml': 'linter:\n  rules:\n    x: true\n'},
        currentShipped: {'a.yaml': 'linter:\n  rules:\n    x: true\n'},
        previousSdk: _sdk,
        currentSdk: '^3.14.0',
      );
      expect(bump, Bump.minor);
    });
  });

  group('changedShippedPaths', () {
    test('lists only files whose parsed content differs', () {
      final changed = changedShippedPaths(
        previous: {
          'a.yaml': 'x: 1 # old',
          'b.yaml': 'y: 1',
          'gone.yaml': 'z: 1',
        },
        current: {'a.yaml': 'x: 1 # new', 'b.yaml': 'y: 2', 'new.yaml': 'w: 1'},
      );
      expect(changed, {'b.yaml', 'gone.yaml', 'new.yaml'});
    });
  });

  group('nextVersion', () {
    test('applies the bump to a semantic version', () {
      expect(nextVersion('1.2.3', Bump.major), '2.0.0');
      expect(nextVersion('1.2.3', Bump.minor), '1.3.0');
      expect(nextVersion('1.2.3', Bump.none), '1.2.3');
    });
  });
}
