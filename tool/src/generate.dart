import 'package:yaml/yaml.dart';

/// Renders a complete options file whose only job is to promote [promoted]
/// to error severity, optionally including a parent options file first.
String errorsFile({required Iterable<String> promoted, String? include}) {
  final names = promoted.toSet().toList()..sort();
  return [
    '# GENERATED CODE - DO NOT MODIFY BY HAND',
    '# Regenerate with `dart run tool/generate.dart`. Promotes every rule',
    '# enabled by the including options file, plus every analyzer diagnostic',
    '# whose default severity is warning or info, to error.',
    if (include != null) ...['', 'include: $include'],
    '',
    'analyzer:',
    '  errors:',
    for (final name in names) '    $name: error',
    '',
  ].join('\n');
}

/// Every rule key under `linter.rules`, enabled or disabled.
Set<String> listedRuleNames(String options) =>
    _rules(options).keys.whereType<String>().toSet();

/// The rule keys under `linter.rules` that are set to `true`.
Set<String> enabledRuleNames(String options) => {
  for (final MapEntry(:key, :value) in _rules(options).entries)
    if (key is String && value == true) key,
};

Map<Object?, Object?> _rules(String options) {
  final doc = loadYaml(options);
  if (doc is! YamlMap) {
    return const {};
  }
  final rules = (doc['linter'] as YamlMap?)?['rules'];
  return rules is YamlMap ? rules : const {};
}

/// Rules that the SDK expects a decision on but that [listed] lacks.
Set<String> missingRules({
  required Set<String> expected,
  required Set<String> listed,
}) => expected.difference(listed);
