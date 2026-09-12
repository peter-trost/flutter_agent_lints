import 'dart:math';

/// One arm of the agent benchmark, named by its config string:
/// `<options>`, `<options>+skill`, `<options>+skill-<label>`, each
/// optionally followed by `@<arm>` to start from the `lib/` a recorded run
/// of that arm produced instead of from the empty base app.
class Arm {
  const new({required this.options, required this.withSkill, this.seed});

  factory parse(String config) {
    final parts = config.split('@');
    final own = parts.first;
    return Arm(
      options: own.split('+').first,
      withSkill: own.contains('+skill'),
      seed: parts.length > 1 ? parts[1] : null,
    );
  }

  /// The file under `agents/options`, without extension.
  final String options;

  /// Whether the package's skill is installed in the workdir.
  final bool withSkill;

  /// The config whose recorded output seeds the workdir, if any.
  final String? seed;
}

/// Lines added plus lines removed between two sources, by longest common
/// subsequence of lines.
int changedLines(String before, String after) {
  final a = before.split('\n');
  final b = after.split('\n');
  var previous = List<int>.filled(b.length + 1, 0);
  for (final lineA in a) {
    final current = List<int>.filled(b.length + 1, 0);
    for (var j = 0; j < b.length; j++) {
      current[j + 1] = lineA == b[j]
          ? previous[j] + 1
          : max(previous[j + 1], current[j]);
    }
    previous = current;
  }
  final common = previous[b.length];
  return (a.length - common) + (b.length - common);
}
