import 'dart:math';

final _token = RegExp(r'[A-Za-z_][A-Za-z0-9_]*|\d+|\S');
final _comment = RegExp(r'//[^\n]*|/\*[\s\S]*?\*/');

/// Dart source as a token sequence, comments and whitespace removed.
List<String> tokens(String source) => _token
    .allMatches(source.replaceAll(_comment, ''))
    .map((m) => m[0]!)
    .toList();

/// One minus the token edit distance over the longer length: 1 for the
/// same code, 0 for nothing in common.
double similarity(String a, String b) {
  final ta = tokens(a);
  final tb = tokens(b);
  final longest = max(ta.length, tb.length);
  if (longest == 0) {
    return 1;
  }
  return 1 - _editDistance(ta, tb) / longest;
}

/// Mean [similarity] over every pair, or null with fewer than two sources.
double? meanPairwiseSimilarity(List<String> sources) {
  if (sources.length < 2) {
    return null;
  }
  var sum = 0.0;
  var pairs = 0;
  for (var i = 0; i < sources.length; i++) {
    for (var j = i + 1; j < sources.length; j++) {
      sum += similarity(sources[i], sources[j]);
      pairs++;
    }
  }
  return sum / pairs;
}

int _editDistance(List<String> a, List<String> b) {
  var previous = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      current[j] = min(min(previous[j] + 1, current[j - 1] + 1), substitution);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}
