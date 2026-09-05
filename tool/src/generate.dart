import 'package:yaml/yaml.dart';

const beginMarker = '# BEGIN GENERATED';
const endMarker = '# END GENERATED';

/// Returns [options] with the block between [beginMarker] and [endMarker]
/// replaced by one `name: error` line per enabled lint rule and per name in
/// [diagnostics], all sorted.
String generateErrorsBlock(
  String options, {
  required Iterable<String> diagnostics,
}) {
  final lines = options.split('\n');
  final begin = lines.indexWhere((l) => l.trim() == beginMarker);
  final end = lines.indexWhere((l) => l.trim() == endMarker);
  if (begin == -1 || end == -1 || end < begin) {
    throw const FormatException(
      'Expected "$beginMarker" followed by "$endMarker" in the options file.',
    );
  }
  final indent = lines[begin].substring(0, lines[begin].indexOf('#'));
  final names = {..._enabledRules(options), ...diagnostics}.toList()..sort();
  final block = names.map((n) => '$indent$n: error');
  return [
    ...lines.sublist(0, begin + 1),
    ...block,
    ...lines.sublist(end),
  ].join('\n');
}

/// Every rule key under `linter.rules`, enabled or disabled.
Set<String> listedRuleNames(String options) =>
    _rules(options).keys.whereType<String>().toSet();

Set<String> _enabledRules(String options) => {
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

/// Rules that the SDK requires a decision on but that [listed] lacks.
Set<String> missingRules({
  required Set<String> required,
  required Set<String> listed,
}) => required.difference(listed);
