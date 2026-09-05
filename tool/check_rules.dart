import 'dart:io';

import 'package:yaml/yaml.dart';

import 'src/generate.dart';
import 'src/sdk_rules.dart';

/// Verifies that the option files decide on every lint rule of the installed
/// SDK: every stable rule in `lib/analysis_options.yaml`, every experimental
/// rule in `lib/experimental.yaml`, and nothing the SDK does not know.
///
/// The rule list comes from the SDK repository at the tag of the running
/// SDK. Rules that the installed analyzer reports as deprecated or removed
/// are not required, because listing them is itself a warning.
Future<void> main() async {
  final sdkVersion = Platform.version.split(' ').first;
  final rulesJson = await _fetchRulesJson(sdkVersion);
  final known = allRuleNames(rulesJson);
  var failed = false;

  for (final (path, state) in [
    ('lib/analysis_options.yaml', 'stable'),
    ('lib/experimental.yaml', 'experimental'),
  ]) {
    final listed = listedRuleNames(File(path).readAsStringSync());
    final required = ruleNamesWithState(rulesJson, state);
    final missing = missingRules(required: required, listed: listed);
    final unusable = missing.isEmpty
        ? const <String>{}
        : await _unusableAccordingToAnalyzer(missing);
    final undecided = missing.difference(unusable);
    final unknown = listed.difference(known);

    stdout.writeln(
      '$path: ${listed.length} listed, ${required.length} $state in SDK '
      '$sdkVersion, ${unusable.length} deprecated or removed by the analyzer',
    );
    if (undecided.isNotEmpty) {
      failed = true;
      stderr.writeln('  undecided rules (add each as true or false):');
      undecided.toList().sorted().forEach((r) => stderr.writeln('    $r'));
    }
    if (unknown.isNotEmpty) {
      failed = true;
      stderr.writeln('  rules unknown to SDK $sdkVersion:');
      unknown.toList().sorted().forEach((r) => stderr.writeln('    $r'));
    }
  }

  if (failed) {
    exitCode = 1;
  }
}

Future<String> _fetchRulesJson(String sdkVersion) async {
  final uri = Uri.https(
    'raw.githubusercontent.com',
    '/dart-lang/sdk/$sdkVersion/pkg/linter/tool/machine/rules.json',
  );
  final client = HttpClient();
  try {
    final response = await client.getUrl(uri).then((r) => r.close());
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    return await response.transform(const SystemEncoding().decoder).join();
  } finally {
    client.close();
  }
}

/// Enables [rules] in a throwaway project and asks the installed analyzer
/// which of them it reports as deprecated or removed.
///
/// The probe declares the same SDK constraint as this package, because rule
/// deprecation is tied to the language version: a rule deprecated in 3.13 is
/// still fine for a project whose language version is 3.0.
Future<Set<String>> _unusableAccordingToAnalyzer(Set<String> rules) async {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final sdkConstraint = (pubspec['environment'] as YamlMap)['sdk'];
  final dir = await Directory.systemTemp.createTemp('flutter_agent_lints_');
  try {
    File(
      '${dir.path}/pubspec.yaml',
    ).writeAsStringSync('name: probe\nenvironment:\n  sdk: "$sdkConstraint"\n');
    File('${dir.path}/analysis_options.yaml').writeAsStringSync(
      'linter:\n  rules:\n${rules.map((r) => '    - $r\n').join()}',
    );
    // Without a package config the analyzer has no language version for the
    // project and skips version-dependent deprecations.
    await Process.run('dart', [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: dir.path);
    final result = await Process.run('dart', [
      'analyze',
      '--format=machine',
      dir.path,
    ]);
    return unusableRulesFromAnalyzerOutput('${result.stdout}${result.stderr}');
  } finally {
    await dir.delete(recursive: true);
  }
}

extension on List<String> {
  List<String> sorted() => this..sort();
}
