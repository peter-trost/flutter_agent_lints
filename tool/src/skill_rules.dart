/// Rule names a skill file mentions in backticks, which are the names the
/// analyzer would report. Prose about a rule reads the same as its code, so
/// only backticked names count.
Set<String> mentionedRules(String skill) =>
    RegExp('`([a-z][a-z0-9_]{4,})`')
        .allMatches(skill)
        .map((m) => m.group(1)!)
        .toSet();

/// Rules the option file turns off, by name.
Set<String> disabledRules(String options) => RegExp(
  r'^\s{4}([a-z][a-z0-9_]*): false',
  multiLine: true,
).allMatches(options).map((m) => m.group(1)!).toSet();

/// Rules the option file turns on, by name.
Set<String> enabledRules(String options) => RegExp(
  r'^\s{4}([a-z][a-z0-9_]*): true',
  multiLine: true,
).allMatches(options).map((m) => m.group(1)!).toSet();

/// Rules a skill file describes that the ruleset does not enable.
///
/// A mention only counts when the option file knows the name at all, so
/// prose that happens to look like a rule name (`analysis_options`, a Dart
/// identifier in a sentence) cannot fail the check. Analyzer diagnostics
/// that are not lint rules, such as `strict_raw_type`, are likewise not
/// listed in the option file's `linter` section and are skipped.
List<String> staleRules({required String skill, required String options}) {
  final known = {...enabledRules(options), ...disabledRules(options)};
  final enabled = enabledRules(options);
  return (mentionedRules(
        skill,
      )..removeWhere((rule) => !known.contains(rule) || enabled.contains(rule)))
      .toList()
    ..sort();
}
