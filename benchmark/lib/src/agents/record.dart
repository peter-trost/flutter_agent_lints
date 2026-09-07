/// Everything measured on one agent run.
class RunRecord {
  const new({
    required this.task,
    required this.config,
    required this.rep,
    required this.model,
    required this.subtype,
    required this.numTurns,
    required this.durationMs,
    required this.costUsd,
    required this.inputTokens,
    required this.outputTokens,
    required this.testsPassed,
    required this.testsTotal,
    required this.analyzeIssues,
    required this.fullIssues,
    required this.fullByRule,
    required this.ignores,
    required this.optionsModified,
    required this.ruleMentions,
    required this.loc,
    required this.source,
  });

  factory fromJson(Map<String, Object?> json) => RunRecord(
    task: json['task']! as String,
    config: json['config']! as String,
    rep: json['rep']! as int,
    model: json['model']! as String,
    subtype: json['subtype']! as String,
    numTurns: json['numTurns']! as int,
    durationMs: json['durationMs']! as int,
    costUsd: (json['costUsd']! as num).toDouble(),
    inputTokens: json['inputTokens']! as int,
    outputTokens: json['outputTokens']! as int,
    testsPassed: json['testsPassed']! as int,
    testsTotal: json['testsTotal']! as int,
    analyzeIssues: json['analyzeIssues']! as int,
    fullIssues: json['fullIssues']! as int,
    fullByRule: (json['fullByRule']! as Map<String, Object?>)
        .cast<String, int>(),
    ignores: json['ignores']! as int,
    optionsModified: json['optionsModified']! as bool,
    ruleMentions: (json['ruleMentions']! as Map<String, Object?>)
        .cast<String, int>(),
    loc: json['loc']! as int,
    source: json['source']! as String,
  );

  final String task;
  final String config;
  final int rep;
  final String model;

  /// `success`, `error_max_turns`, `no_result`, and so on.
  final String subtype;
  final int numTurns;
  final int durationMs;
  final double costUsd;
  final int inputTokens;
  final int outputTokens;

  /// Hidden tests, run after the agent finished.
  final int testsPassed;
  final int testsTotal;

  /// Diagnostics left under the run's own option set.
  final int analyzeIssues;

  /// Diagnostics of `lib/` under the full flutter_agent_lints options: how
  /// far the result is from the strict set, whatever the run used.
  final int fullIssues;
  final Map<String, int> fullByRule;

  /// `ignore` comments the agent added.
  final int ignores;

  /// Whether the agent edited `analysis_options.yaml` despite the prompt.
  final bool optionsModified;

  /// Rule codes in analyzer output the agent read during the run.
  final Map<String, int> ruleMentions;

  /// Lines of Dart under `lib/` at the end.
  final int loc;

  /// The task's solution file at the end, for the consistency measure.
  final String source;

  String get id => '$task/$config/$rep/$model';

  Map<String, Object?> toJson() => {
    'task': task,
    'config': config,
    'rep': rep,
    'model': model,
    'subtype': subtype,
    'numTurns': numTurns,
    'durationMs': durationMs,
    'costUsd': costUsd,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'testsPassed': testsPassed,
    'testsTotal': testsTotal,
    'analyzeIssues': analyzeIssues,
    'fullIssues': fullIssues,
    'fullByRule': fullByRule,
    'ignores': ignores,
    'optionsModified': optionsModified,
    'ruleMentions': ruleMentions,
    'loc': loc,
    'source': source,
  };
}
