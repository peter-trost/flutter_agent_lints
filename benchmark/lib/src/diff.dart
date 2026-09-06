/// Line numbers touched by a unified diff, on the side before the change
/// (deleted or replaced lines) and on the side after it (added or replaced
/// lines).
class ChangedLines {
  const new({required this.before, required this.after});

  final Set<int> before;
  final Set<int> after;
}

final _hunkHeader = RegExp(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@');

/// Reads the hunk headers of a `git diff -U0` for one file.
ChangedLines changedLinesFromUnifiedDiff(String diff) {
  final before = <int>{};
  final after = <int>{};
  for (final line in diff.split('\n')) {
    final match = _hunkHeader.firstMatch(line);
    if (match == null) {
      continue;
    }
    before.addAll(_range(match.group(1)!, match.group(2)));
    after.addAll(_range(match.group(3)!, match.group(4)));
  }
  return ChangedLines(before: before, after: after);
}

Iterable<int> _range(String start, String? count) {
  final first = int.parse(start);
  final length = count == null ? 1 : int.parse(count);
  return Iterable<int>.generate(length, (i) => first + i);
}
