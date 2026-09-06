import 'dart:convert';

/// One diagnostic from `dart analyze --format=json`.
class Diagnostic {
  const new({
    required this.code,
    required this.type,
    required this.file,
    required this.line,
  });

  final String code;

  /// The analyzer's diagnostic type: `LINT`, `STATIC_WARNING`, `HINT`,
  /// `COMPILE_TIME_ERROR`, `SYNTACTIC_ERROR`, and so on. Unlike the severity
  /// it does not change when an option file promotes the diagnostic.
  final String type;

  /// Path relative to the analyzed package.
  final String file;

  /// One-based line of the diagnostic's start.
  final int line;

  /// Whether the option file decides if this diagnostic fires. Compile and
  /// syntax errors fire under any options, so they say nothing about a lint
  /// set; they also appear when a corpus commit does not build with the
  /// installed SDK.
  bool get countsForOptions =>
      type != 'COMPILE_TIME_ERROR' && type != 'SYNTACTIC_ERROR';
}

/// Parses the JSON that `dart analyze --format=json` prints. File paths are
/// made relative to [packageRoot].
List<Diagnostic> parseAnalyzeJson(String json, {required String packageRoot}) {
  final prefix = packageRoot.endsWith('/') ? packageRoot : '$packageRoot/';
  final decoded = jsonDecode(json) as Map<String, Object?>;
  final diagnostics = decoded['diagnostics']! as List<Object?>;
  return [
    for (final entry in diagnostics.cast<Map<String, Object?>>())
      _fromJson(entry, prefix),
  ];
}

Diagnostic _fromJson(Map<String, Object?> entry, String prefix) {
  final location = entry['location']! as Map<String, Object?>;
  final range = location['range']! as Map<String, Object?>;
  final start = range['start']! as Map<String, Object?>;
  final file = location['file']! as String;
  return Diagnostic(
    code: entry['code']! as String,
    type: entry['type']! as String,
    file: file.startsWith(prefix) ? file.substring(prefix.length) : file,
    line: start['line']! as int,
  );
}
