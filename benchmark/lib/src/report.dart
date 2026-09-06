import 'package:lint_benchmark/src/score.dart';

const _start = '<!-- benchmark -->\n';
const _end = '<!-- /benchmark -->';

/// Renders the summary tables for the README from one [Aggregate] per
/// option set.
String renderReport(
  Map<String, Aggregate> byOptionSet, {
  required List<String> repos,
  required int commits,
}) {
  final buffer = StringBuffer()
    ..writeln(
      'Corpus: $commits bug-fix commits from ${repos.join(', ')}. '
      'Fixed lines are the lines each fix deleted or replaced; a line is '
      'flagged when it carried a diagnostic that the fix made go away. '
      'Lift compares that with how often any line of the same files '
      'carries a diagnostic.',
    )
    ..writeln()
    ..writeln(
      '| Option set | Commits flagged | Fixed lines flagged | '
      'Any line flagged | Lift |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final entry in byOptionSet.entries) {
    final a = entry.value;
    buffer.writeln(
      '| ${entry.key} | ${a.commitsFlagged} of ${a.commits} | '
      '${a.hitLines} of ${a.fixLines} (${_percent(a.hitRate)}) | '
      '${_percent(a.density)} | ${a.lift.toStringAsFixed(1)}x |',
    );
  }

  for (final entry in byOptionSet.entries) {
    final rules = entry.value.hitsByRule.entries.toList()
      ..sort((a, b) {
        final byHits = b.value.compareTo(a.value);
        return byHits != 0 ? byHits : a.key.compareTo(b.key);
      });
    if (rules.isEmpty) {
      continue;
    }
    buffer
      ..writeln()
      ..writeln('Rules of ${entry.key} that flagged the most fixed lines:')
      ..writeln()
      ..writeln('| Rule | Fixed lines | Commits | Lift |')
      ..writeln('| --- | --- | --- | --- |');
    for (final rule in rules.take(15)) {
      buffer.writeln(
        '| ${rule.key} | ${rule.value} | '
        '${entry.value.commitsByRule[rule.key]} | '
        '${entry.value.ruleLift(rule.key).toStringAsFixed(1)}x |',
      );
    }
  }
  return buffer.toString();
}

String _percent(double share) => '${(share * 100).toStringAsFixed(1)}%';

/// Replaces the text between the benchmark markers of [text] with
/// [replacement], keeping the markers.
String replaceBetweenMarkers(String text, String replacement) {
  final start = text.indexOf(_start);
  final end = text.indexOf(_end);
  if (start < 0 || end < 0 || end < start) {
    throw StateError('benchmark markers not found');
  }
  return text.replaceRange(start + _start.length, end, replacement);
}
