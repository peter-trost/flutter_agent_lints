import 'package:lint_benchmark/src/diff.dart';
import 'package:test/test.dart';

void main() {
  group('changedLinesFromUnifiedDiff', () {
    test('maps every hunk header to line sets on both sides', () {
      const diff = '''
diff --git a/lib/a.dart b/lib/a.dart
--- a/lib/a.dart
+++ b/lib/a.dart
@@ -3,2 +3,3 @@ class A {
-old
-old2
+new
+new2
+new3
@@ -10 +11,0 @@
-gone
@@ -20,0 +21 @@
+added
''';
      final lines = changedLinesFromUnifiedDiff(diff);
      expect(lines.before, {3, 4, 10});
      expect(lines.after, {3, 4, 5, 21});
    });

    test('an empty diff changes nothing', () {
      final lines = changedLinesFromUnifiedDiff('');
      expect(lines.before, isEmpty);
      expect(lines.after, isEmpty);
    });
  });
}
