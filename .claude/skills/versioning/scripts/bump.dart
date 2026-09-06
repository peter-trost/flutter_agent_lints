import 'dart:io';

import 'package:yaml/yaml.dart';

import '../../../../tool/src/bump.dart';

/// Decides the version bump since the last release tag and prints it.
///
/// Run from the package root: `dart run .claude/skills/versioning/scripts/bump.dart`.
/// Output, one key per line: `previous` (tag or `none`), `bump`, `current`
/// and `next` version, and a `reason` line per shipped file that changed.
/// With no release tag yet the bump is `initial` and `next` is the version
/// already in pubspec.yaml.
Future<void> main() async {
  final tag = await _lastReleaseTag();
  final currentPubspec = _pubspec(File('pubspec.yaml').readAsStringSync());
  final currentVersion = currentPubspec['version']! as String;
  final currentShipped = _shippedNow();

  if (tag == null) {
    _print([
      ('previous', 'none'),
      ('bump', 'initial'),
      ('next', currentVersion),
    ]);
    return;
  }

  final previousShipped = await _shippedAt(tag, {
    ...currentShipped.keys,
    ...await _shippedPathsAt(tag),
  });
  final previousSdk = _sdk(_pubspec(await _gitShow(tag, 'pubspec.yaml') ?? ''));
  final bump = decideBump(
    previousShipped: previousShipped,
    currentShipped: currentShipped,
    previousSdk: previousSdk,
    currentSdk: _sdk(currentPubspec),
  );
  _print([
    ('previous', tag),
    ('bump', bump.name),
    ('current', currentVersion),
    ('next', nextVersion(currentVersion, bump)),
    for (final path in {...previousShipped.keys, ...currentShipped.keys})
      if (previousShipped[path] != currentShipped[path])
        ('reason', '$path differs from $tag'),
    if (previousSdk != _sdk(currentPubspec))
      ('reason', 'environment.sdk moved from $previousSdk'),
  ]);
}

Map<String, String> _shippedNow() => {
  for (final file in Directory('lib').listSync().whereType<File>())
    if (file.path.endsWith('.yaml')) file.path: file.readAsStringSync(),
};

Future<Set<String>> _shippedPathsAt(String tag) async {
  final result = await Process.run('git', [
    'ls-tree',
    '--name-only',
    tag,
    'lib/',
  ]);
  return {
    for (final line in (result.stdout as String).split('\n'))
      if (line.endsWith('.yaml')) line,
  };
}

Future<Map<String, String>> _shippedAt(String tag, Set<String> paths) async => {
  for (final path in paths)
    path: ?await _gitShow(tag, path),
};

Future<String?> _gitShow(String tag, String path) async {
  final result = await Process.run('git', ['show', '$tag:$path']);
  return result.exitCode == 0 ? result.stdout as String : null;
}

Future<String?> _lastReleaseTag() async {
  final result = await Process.run('git', [
    'describe',
    '--tags',
    '--abbrev=0',
    '--match',
    'v*',
  ]);
  return result.exitCode == 0 ? (result.stdout as String).trim() : null;
}

/// The pubspec as a map, or an empty map when [text] is not one (a tag from
/// before the package existed).
YamlMap _pubspec(String text) => switch (loadYaml(text)) {
  final YamlMap map => map,
  _ => YamlMap(),
};

String _sdk(YamlMap pubspec) => switch (pubspec['environment']) {
  final YamlMap environment => environment['sdk'] as String? ?? '',
  _ => '',
};

void _print(List<(String, String)> lines) {
  for (final (key, value) in lines) {
    stdout.writeln('$key: $value');
  }
}
