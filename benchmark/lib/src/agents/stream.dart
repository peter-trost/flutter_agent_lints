import 'dart:convert';

/// The final accounting of one headless `claude -p` run.
class RunResult {
  const new({
    required this.subtype,
    required this.numTurns,
    required this.durationMs,
    required this.costUsd,
    required this.inputTokens,
    required this.outputTokens,
  });

  final String subtype;
  final int numTurns;
  final int durationMs;
  final double costUsd;

  /// Fresh, cached and cache-building input tokens together.
  final int inputTokens;
  final int outputTokens;
}

/// Reads the `result` event that ends a `--output-format stream-json` run.
RunResult parseResult(String stream) {
  for (final line in stream.split('\n').reversed) {
    if (!line.startsWith('{')) {
      continue;
    }
    final event = jsonDecode(line) as Map<String, Object?>;
    if (event['type'] != 'result') {
      continue;
    }
    final usage = (event['usage'] as Map<String, Object?>?) ?? const {};
    int tokens(String key) => (usage[key] as num?)?.toInt() ?? 0;
    return RunResult(
      subtype: event['subtype'] as String? ?? 'unknown',
      numTurns: (event['num_turns'] as num?)?.toInt() ?? 0,
      durationMs: (event['duration_ms'] as num?)?.toInt() ?? 0,
      costUsd: (event['total_cost_usd'] as num?)?.toDouble() ?? 0,
      inputTokens:
          tokens('input_tokens') +
          tokens('cache_read_input_tokens') +
          tokens('cache_creation_input_tokens'),
      outputTokens: tokens('output_tokens'),
    );
  }
  return const RunResult(
    subtype: 'no_result',
    numTurns: 0,
    durationMs: 0,
    costUsd: 0,
    inputTokens: 0,
    outputTokens: 0,
  );
}

final _diagnosticLine = RegExp(
  r'^\s*(?:error|warning|info) - .* - ([a-z_][a-z0-9_]*)\s*$',
  multiLine: true,
);

/// How often each rule code appeared in analyzer output the agent read
/// during the run: the price of a rule set in fix-loop iterations.
Map<String, int> ruleMentions(String stream) {
  final counts = <String, int>{};
  for (final line in stream.split('\n')) {
    if (!line.startsWith('{')) {
      continue;
    }
    final event = jsonDecode(line) as Map<String, Object?>;
    if (event['type'] != 'user') {
      continue;
    }
    for (final text in _toolResultTexts(event)) {
      for (final match in _diagnosticLine.allMatches(text)) {
        counts.update(match.group(1)!, (n) => n + 1, ifAbsent: () => 1);
      }
    }
  }
  return counts;
}

Iterable<String> _toolResultTexts(Map<String, Object?> event) sync* {
  final message = event['message'] as Map<String, Object?>?;
  final content = message?['content'];
  if (content is! List<Object?>) {
    return;
  }
  for (final block in content.cast<Map<String, Object?>>()) {
    if (block['type'] != 'tool_result') {
      continue;
    }
    final inner = block['content'];
    if (inner is String) {
      yield inner;
    } else if (inner is List<Object?>) {
      for (final part in inner.cast<Map<String, Object?>>()) {
        if (part['text'] case final String text) {
          yield text;
        }
      }
    }
  }
}

/// Passed and total tests from `flutter test --reporter json` output.
({int passed, int total}) countTests(String reporter) {
  var passed = 0;
  var total = 0;
  for (final line in reporter.split('\n')) {
    if (!line.startsWith('{')) {
      continue;
    }
    final event = jsonDecode(line) as Map<String, Object?>;
    if (event['type'] != 'testDone' || event['hidden'] == true) {
      continue;
    }
    total++;
    if (event['result'] == 'success') {
      passed++;
    }
  }
  return (passed: passed, total: total);
}
