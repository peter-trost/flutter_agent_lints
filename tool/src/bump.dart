import 'dart:convert';

import 'package:yaml/yaml.dart';

/// The kind of version bump a change requires.
enum Bump { none, minor, major }

/// Decides the bump from what consumers can observe.
///
/// [previousShipped] and [currentShipped] map each shipped options file
/// (everything under `lib/`) to its text at the last release and now. Files
/// are compared as parsed YAML, so comment-only edits do not count. Any
/// semantic difference, including a file appearing or disappearing, changes
/// what the analyzer enforces for every consumer and is therefore [Bump.major].
/// A moved SDK lower bound with an unchanged rule set is [Bump.minor].
/// Anything else is invisible to consumers: [Bump.none].
Bump decideBump({
  required Map<String, String> previousShipped,
  required Map<String, String> currentShipped,
  required String previousSdk,
  required String currentSdk,
}) {
  final previous = previousShipped.map((k, v) => MapEntry(k, _canonical(v)));
  final current = currentShipped.map((k, v) => MapEntry(k, _canonical(v)));
  if (jsonEncode(_sorted(previous)) != jsonEncode(_sorted(current))) {
    return Bump.major;
  }
  if (previousSdk != currentSdk) {
    return Bump.minor;
  }
  return Bump.none;
}

/// Applies [bump] to a `major.minor.patch` version string.
String nextVersion(String version, Bump bump) {
  final [major, minor, patch] = version.split('.').map(int.parse).toList();
  return switch (bump) {
    Bump.major => '${major + 1}.0.0',
    Bump.minor => '$major.${minor + 1}.0',
    Bump.none => '$major.$minor.$patch',
  };
}

String _canonical(String yamlText) => jsonEncode(loadYaml(yamlText));

Map<String, String> _sorted(Map<String, String> map) => Map.fromEntries(
  map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
);
