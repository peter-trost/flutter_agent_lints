import 'package:test/test.dart';

import '../tool/src/skill_samples.dart';

void main() {
  group('samplesIn', () {
    test('extracts each fenced dart block', () {
      const markdown = '''
Text.

```dart
void a() {}
```

More.

```dart
void b() {}
```
''';
      final samples = samplesIn(file: 'dart.md', markdown: markdown);
      expect(samples, hasLength(2));
      expect(samples.first.code.trim(), 'void a() {}');
      expect(samples.last.code.trim(), 'void b() {}');
    });

    test('removes the indentation of a block nested in a list item', () {
      const markdown = '''
- A point:

  ```dart
  void a() {
    b();
  }
  ```
''';
      final samples = samplesIn(file: 'flutter.md', markdown: markdown);
      expect(samples.single.code, 'void a() {\n  b();\n}\n');
    });

    test('ignores fences of other languages', () {
      const markdown = '```bash\ndart analyze\n```\n';
      expect(samplesIn(file: 'x.md', markdown: markdown), isEmpty);
    });

    test('names a sample after its file and position', () {
      const markdown = '```dart\nvoid a() {}\n```\n';
      expect(
        samplesIn(file: 'dart.md', markdown: markdown).single.name,
        'dart_md_0.dart',
      );
    });
  });

  _placement();
}

void _placement() {
  group('Sample.isTest', () {
    test('is true when the sample imports a test framework', () {
      const markdown =
          "```dart\nimport 'package:flutter_test/flutter_test.dart';\n```\n";
      expect(
        samplesIn(file: 'dart.md', markdown: markdown).single.isTest,
        isTrue,
      );
    });

    test('is false for a sample that imports nothing test-related', () {
      const markdown =
          "```dart\nimport 'package:flutter/material.dart';\n```\n";
      expect(
        samplesIn(file: 'dart.md', markdown: markdown).single.isTest,
        isFalse,
      );
    });
  });
}
