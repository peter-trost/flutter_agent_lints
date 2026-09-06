import 'package:yaml/yaml.dart';

/// The lowest SDK version an `environment: sdk` constraint admits, for
/// example `3.13.0` from `^3.13.0` or `>=3.13.0 <4.0.0`.
String sdkLowerBound(String constraint) =>
    RegExp(r'\d+\.\d+\.\d+').firstMatch(constraint)!.group(0)!;

/// The analyzer version an SDK bundles, read from `pkg/analyzer/pubspec.yaml`
/// at the SDK's tag. The repository carries a `-dev` suffix that the
/// published package does not.
String bundledAnalyzerVersion(String analyzerPubspec) {
  final version = (loadYaml(analyzerPubspec) as YamlMap)['version'] as String;
  return version.replaceFirst(RegExp(r'-dev$'), '');
}
