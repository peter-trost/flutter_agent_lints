import 'package:yaml/yaml.dart';

/// Resolves an option file's include chain into one self-contained file
/// listing every rule, so a corpus repository can use the option set without
/// depending on the packages that ship it.
String flattenOptions(
  String entryUri, {
  required String Function(String uri) read,
}) {
  final rules = <String>{};
  String? uri = entryUri;
  while (uri != null) {
    final doc = loadYaml(read(uri)) as YamlMap;
    final linter = doc['linter'] as YamlMap?;
    final listed = linter?['rules'] as YamlList?;
    rules.addAll(listed?.cast<String>() ?? const []);
    uri = doc['include'] as String?;
  }
  final buffer = StringBuffer()
    ..writeln('# Flattened from $entryUri by lint_benchmark.')
    ..writeln('linter:')
    ..writeln('  rules:');
  for (final rule in rules.toList()..sort()) {
    buffer.writeln('    - $rule');
  }
  return buffer.toString();
}
