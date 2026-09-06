import 'package:lint_benchmark/src/diagnostics.dart';
import 'package:lint_benchmark/src/diff.dart';

/// What one option set saw on one bug-fix commit.
class CommitScore {
  const new({
    required this.fixLines,
    required this.hitLines,
    required this.diagnosticLines,
    required this.totalLines,
    required this.hitsByRule,
    required this.linesByRule,
  });

  factory fromJson(Map<String, Object?> json) => CommitScore(
    fixLines: json['fixLines']! as int,
    hitLines: json['hitLines']! as int,
    diagnosticLines: json['diagnosticLines']! as int,
    totalLines: json['totalLines']! as int,
    hitsByRule: (json['hitsByRule']! as Map<String, Object?>)
        .cast<String, int>(),
    linesByRule: (json['linesByRule']! as Map<String, Object?>)
        .cast<String, int>(),
  );

  /// Lines the fix deleted or replaced, over all touched files.
  final int fixLines;

  /// Fix lines that carried a diagnostic before the fix which is gone from
  /// the fix's replacement lines afterwards.
  final int hitLines;

  /// Lines of the touched files (before the fix) with at least one
  /// diagnostic. With [totalLines] this is the density a random line has.
  final int diagnosticLines;

  /// Lines in the touched files before the fix.
  final int totalLines;

  /// Fix lines flagged per rule.
  final Map<String, int> hitsByRule;

  /// Lines of the touched files (before the fix) flagged per rule, so each
  /// rule's hits can be compared with its own density.
  final Map<String, int> linesByRule;

  Map<String, Object?> toJson() => {
    'fixLines': fixLines,
    'hitLines': hitLines,
    'diagnosticLines': diagnosticLines,
    'totalLines': totalLines,
    'hitsByRule': hitsByRule,
    'linesByRule': linesByRule,
  };
}

/// Scores one commit for one option set.
///
/// [changes] maps each touched file to its changed lines, [before] and
/// [after] are the diagnostics of those files on either side of the fix, and
/// [lineCounts] the length of each file before the fix.
CommitScore scoreCommit({
  required Map<String, ChangedLines> changes,
  required List<Diagnostic> before,
  required List<Diagnostic> after,
  required Map<String, int> lineCounts,
}) {
  final survivors = <String, Set<String>>{};
  for (final d in after.where((d) => d.countsForOptions)) {
    if (changes[d.file]?.after.contains(d.line) ?? false) {
      survivors.putIfAbsent(d.file, () => {}).add(d.code);
    }
  }

  final hitLines = <(String, int)>{};
  final hitsByRule = <String, int>{};
  final diagnosticLines = <(String, int)>{};
  final linesByRule = <String, Set<(String, int)>>{};

  for (final d in before.where((d) => d.countsForOptions)) {
    final change = changes[d.file];
    if (change == null) {
      continue;
    }
    diagnosticLines.add((d.file, d.line));
    linesByRule.putIfAbsent(d.code, () => {}).add((d.file, d.line));
    if (!change.before.contains(d.line)) {
      continue;
    }
    if (survivors[d.file]?.contains(d.code) ?? false) {
      continue;
    }
    hitLines.add((d.file, d.line));
    hitsByRule.update(d.code, (n) => n + 1, ifAbsent: () => 1);
  }

  return CommitScore(
    fixLines: changes.values.fold(0, (n, c) => n + c.before.length),
    hitLines: hitLines.length,
    diagnosticLines: diagnosticLines.length,
    totalLines: changes.keys.fold(0, (sum, f) => sum + (lineCounts[f] ?? 0)),
    hitsByRule: hitsByRule,
    linesByRule: linesByRule.map((k, v) => MapEntry(k, v.length)),
  );
}

/// The sums over every scored commit of one option set.
class Aggregate {
  const new({
    required this.commits,
    required this.commitsFlagged,
    required this.fixLines,
    required this.hitLines,
    required this.diagnosticLines,
    required this.totalLines,
    required this.hitsByRule,
    required this.commitsByRule,
    required this.linesByRule,
  });

  final int commits;
  final int commitsFlagged;
  final int fixLines;
  final int hitLines;
  final int diagnosticLines;
  final int totalLines;
  final Map<String, int> hitsByRule;
  final Map<String, int> commitsByRule;
  final Map<String, int> linesByRule;

  /// Share of fix lines flagged.
  double get hitRate => fixLines == 0 ? 0 : hitLines / fixLines;

  /// Share of all lines in the touched files flagged.
  double get density => totalLines == 0 ? 0 : diagnosticLines / totalLines;

  /// How much likelier a fixed line is to carry a diagnostic than any line
  /// of the same files. One means the option set flags fixed lines no more
  /// often than chance.
  double get lift => _lift(hitLines, diagnosticLines);

  /// [lift] restricted to one rule.
  double ruleLift(String rule) =>
      _lift(hitsByRule[rule] ?? 0, linesByRule[rule] ?? 0);

  double _lift(int hits, int lines) {
    if (fixLines == 0 || totalLines == 0 || lines == 0) {
      return 0;
    }
    return (hits / fixLines) / (lines / totalLines);
  }
}

Aggregate aggregate(Iterable<CommitScore> scores) {
  var commits = 0;
  var commitsFlagged = 0;
  var fixLines = 0;
  var hitLines = 0;
  var diagnosticLines = 0;
  var totalLines = 0;
  final hitsByRule = <String, int>{};
  final commitsByRule = <String, int>{};
  final linesByRule = <String, int>{};
  for (final score in scores) {
    commits++;
    if (score.hitLines > 0) {
      commitsFlagged++;
    }
    fixLines += score.fixLines;
    hitLines += score.hitLines;
    diagnosticLines += score.diagnosticLines;
    totalLines += score.totalLines;
    for (final entry in score.hitsByRule.entries) {
      hitsByRule.update(
        entry.key,
        (n) => n + entry.value,
        ifAbsent: () => entry.value,
      );
      commitsByRule.update(entry.key, (n) => n + 1, ifAbsent: () => 1);
    }
    for (final entry in score.linesByRule.entries) {
      linesByRule.update(
        entry.key,
        (n) => n + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }
  return Aggregate(
    commits: commits,
    commitsFlagged: commitsFlagged,
    fixLines: fixLines,
    hitLines: hitLines,
    diagnosticLines: diagnosticLines,
    totalLines: totalLines,
    hitsByRule: hitsByRule,
    commitsByRule: commitsByRule,
    linesByRule: linesByRule,
  );
}
