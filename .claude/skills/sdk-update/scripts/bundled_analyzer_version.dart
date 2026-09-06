import 'dart:io';

import 'package:yaml/yaml.dart';

import '../../../../tool/src/sdk_version.dart';

/// Prints the analyzer version bundled with the SDK that `pubspec.yaml`
/// declares as its lower bound. That is the version the `analyzer` dev
/// dependency must be pinned to; a newer analyzer knows diagnostic codes the
/// SDK's own analyzer rejects.
///
/// Run from the package root:
/// `dart run .claude/skills/sdk-update/scripts/bundled_analyzer_version.dart`
Future<void> main() async {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final sdk = sdkLowerBound(
    (pubspec['environment'] as YamlMap)['sdk'] as String,
  );
  final uri = Uri.https(
    'raw.githubusercontent.com',
    '/dart-lang/sdk/$sdk/pkg/analyzer/pubspec.yaml',
  );
  final client = HttpClient();
  try {
    final response = await client.getUrl(uri).then((r) => r.close());
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: uri);
    }
    final body = await response
        .transform(const SystemEncoding().decoder)
        .join();
    stdout.writeln(bundledAnalyzerVersion(body));
  } finally {
    client.close();
  }
}
