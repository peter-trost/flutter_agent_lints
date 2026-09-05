import 'dart:convert';

/// Names of the rules in `rules.json` (the linter's machine-readable rule
/// list, `pkg/linter/tool/machine/rules.json` in the SDK) whose `state` is
/// [state].
Set<String> ruleNamesWithState(String rulesJson, String state) => {
  for (final rule in _rules(rulesJson))
    if (rule['state'] == state) rule['name']! as String,
};

/// Names of every rule in `rules.json`, whatever its state.
Set<String> allRuleNames(String rulesJson) => {
  for (final rule in _rules(rulesJson)) rule['name']! as String,
};

/// Rules that the installed analyzer refuses to enable, extracted from
/// `dart analyze --format=machine` output: the `DEPRECATED_LINT` and
/// `REMOVED_LINT` diagnostics each quote the rule name in their message.
///
/// The installed SDK, not `rules.json`, decides what is usable: the two can
/// disagree for a patch release, and only the analyzer's verdict matters to
/// consumers.
Set<String> unusableRulesFromAnalyzerOutput(String output) {
  final quoted = RegExp("'([a-z0-9_]+)'");
  return {
    for (final line in const LineSplitter().convert(output))
      if (line.contains('|DEPRECATED_LINT|') || line.contains('|REMOVED_LINT|'))
        if (quoted.firstMatch(line.split('|').last) case final match?)
          match.group(1)!,
  };
}

Iterable<Map<String, Object?>> _rules(String rulesJson) =>
    (jsonDecode(rulesJson) as List<Object?>).cast<Map<String, Object?>>();
