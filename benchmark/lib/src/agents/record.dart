/// Everything measured on one agent run.
class RunRecord {
  const new({
    required this.task,
    required this.config,
    required this.rep,
    required this.model,
    required this.subtype,
    required this.numTurns,
    required this.tokens,
    required this.testsPassed,
    required this.testsTotal,
    required this.ignores,
    required this.ruleMentions,
    required this.loc,
    this.changedLines,
  });

  factory fromJson(Map<String, Object?> json) => RunRecord(
    task: json['task']! as String,
    config: json['config']! as String,
    rep: json['rep']! as int,
    model: json['model']! as String,
    subtype: json['subtype']! as String,
    numTurns: json['numTurns']! as int,
    tokens: json['tokens']! as int,
    testsPassed: json['testsPassed']! as int,
    testsTotal: json['testsTotal']! as int,
    ignores: json['ignores']! as int,
    ruleMentions: (json['ruleMentions']! as Map<String, Object?>)
        .cast<String, int>(),
    loc: json['loc']! as int,
    changedLines: json['changedLines'] as int?,
  );

  final String task;
  final String config;
  final int rep;
  final String model;

  /// `success`, `error_max_turns`, `no_result`, and so on.
  final String subtype;
  final int numTurns;

  /// Input tokens, cached ones included, plus output tokens.
  final int tokens;

  /// Hidden tests, run after the agent finished.
  final int testsPassed;
  final int testsTotal;

  /// `ignore` comments the agent added, plus one if it edited
  /// `analysis_options.yaml`: ways around the rules the prompt forbids.
  final int ignores;

  /// Rule codes in analyzer output the agent read during the run.
  final Map<String, int> ruleMentions;

  /// Lines of Dart under `lib/` at the end.
  final int loc;

  /// Lines added or removed in the solution file, for a run that started
  /// from another run's output; null for a run that started empty.
  final int? changedLines;

  String get id => '$task/$config/$rep/$model';

  int get diagnosticsRead => ruleMentions.values.fold(0, (a, b) => a + b);

  Map<String, Object?> toJson() => {
    'task': task,
    'config': config,
    'rep': rep,
    'model': model,
    'subtype': subtype,
    'numTurns': numTurns,
    'tokens': tokens,
    'testsPassed': testsPassed,
    'testsTotal': testsTotal,
    'ignores': ignores,
    'ruleMentions': ruleMentions,
    'loc': loc,
    'changedLines': changedLines,
  };
}
