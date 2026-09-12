/// A fenced Dart code block from a skill file.
class Sample {
  const new({required this.file, required this.index, required this.code});

  final String file;

  /// Position of the block within its file, counting from zero.
  final int index;

  /// The block's source, with the indentation of a nested block removed so
  /// it stands alone as a file.
  final String code;

  String get name => '${file.replaceAll(RegExp('[^a-z]'), '_')}_$index.dart';

  /// Whether the sample is a test file, which must live under `test/` to
  /// import a test framework the project lists only as a dev dependency.
  bool get isTest => _testImport.hasMatch(code);
}

final _testImport = RegExp(
  "^import 'package:(flutter_test|test)/",
  multiLine: true,
);

final _fence = RegExp(
  r'```dart\n(.*?)^[ \t]*```',
  multiLine: true,
  dotAll: true,
);

/// The Dart samples in one skill file.
///
/// A block nested under a list item is indented in the Markdown; that
/// indentation is not part of the sample, so it is removed.
List<Sample> samplesIn({required String file, required String markdown}) => [
  for (final (index, match) in _fence.allMatches(markdown).indexed)
    Sample(file: file, index: index, code: _dedent(match.group(1)!)),
];

String _dedent(String block) {
  final lines = block.split('\n');
  final indents = lines
      .where((l) => l.trim().isNotEmpty)
      .map((l) => l.length - l.trimLeft().length);
  if (indents.isEmpty) {
    return block;
  }
  final common = indents.reduce((a, b) => a < b ? a : b);
  return lines
      .map((l) => l.length >= common ? l.substring(common) : l)
      .join('\n');
}
