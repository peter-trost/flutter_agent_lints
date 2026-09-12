import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lint_benchmark/src/agents/arm.dart';
import 'package:lint_benchmark/src/agents/record.dart';
import 'package:lint_benchmark/src/agents/stream.dart';
import 'package:lint_benchmark/src/diagnostics.dart';

/// Runs headless Claude Code agents on the tasks under `agents/tasks`, once
/// per option set under `agents/options`, and appends one record per run
/// to `results/agents/runs.jsonl`. Runs already recorded are skipped, so an
/// interrupted batch resumes.
///
/// Usage: dart run bin/agents.dart [--model opus] [--reps 5]
///   [--tasks a,b] [--configs x,y] [--parallel 2] [--max-turns 60]
///   [--timeout-min 20] [--validate] [--change]
///
/// `--validate` runs each task's reference solution through its hidden
/// tests instead of an agent.
///
/// `--change` runs the change tasks under `agents/changes` instead: each
/// config is `<options>@<seed>`, and rep `n` starts from the `lib/` that
/// rep `n` of the seed config produced on the base task, with the base
/// task's hidden tests in place as the project's tests. Records go to
/// `results/agents/changes.jsonl`.
Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final root = Directory.current.parent.absolute.path;
  final tasks = options.tasks ?? _names(Directory(options.tasksDir));
  final configs =
      options.configs ??
      _names(Directory('agents/options')).map((f) => f.replaceAll('.yaml', ''));

  if (options.validate) {
    for (final task in tasks) {
      await _validate(task, root, options);
    }
    return;
  }

  final done = _loadRecords(options.recordsPath).map((r) => r.id).toSet();
  final queue = <(String, String, int)>[
    for (var rep = 0; rep < options.reps; rep++)
      for (final task in tasks)
        for (final config in configs)
          if (!done.contains('$task/$config/$rep/${options.model}'))
            (task, config, rep),
  ];
  stdout.writeln('${queue.length} runs to do, ${done.length} recorded');

  Future<void> worker() async {
    while (queue.isNotEmpty) {
      final (task, config, rep) = queue.removeAt(0);
      final record = await _run(task, config, rep, options, root);
      File(options.recordsPath).writeAsStringSync(
        '${jsonEncode(record.toJson())}\n',
        mode: FileMode.append,
      );
      stdout.writeln(
        '${record.id}: ${record.subtype}, ${record.numTurns} turns, '
        '${record.testsPassed}/${record.testsTotal} tests, '
        '${record.fullIssues} strict issues',
      );
    }
  }

  await Future.wait([for (var i = 0; i < options.parallel; i++) worker()]);
}

const _allowedTools = 'Read,Edit,Write,Glob,Grep,Bash(dart:*),Bash(flutter:*)';

class _Options {
  const new({
    required this.model,
    required this.reps,
    required this.tasks,
    required this.configs,
    required this.parallel,
    required this.maxTurns,
    required this.timeout,
    required this.validate,
    required this.change,
  });

  factory parse(List<String> args) {
    var model = 'opus';
    var reps = 5;
    List<String>? tasks;
    List<String>? configs;
    var parallel = 2;
    var maxTurns = 60;
    var timeoutMin = 20;
    var validate = false;
    var change = false;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--model':
          model = args[++i];
        case '--reps':
          reps = int.parse(args[++i]);
        case '--tasks':
          tasks = args[++i].split(',');
        case '--configs':
          configs = args[++i].split(',');
        case '--parallel':
          parallel = int.parse(args[++i]);
        case '--max-turns':
          maxTurns = int.parse(args[++i]);
        case '--timeout-min':
          timeoutMin = int.parse(args[++i]);
        case '--validate':
          validate = true;
        case '--change':
          change = true;
        default:
          throw ArgumentError('unknown argument ${args[i]}');
      }
    }
    return _Options(
      model: model,
      reps: reps,
      tasks: tasks,
      configs: configs,
      parallel: parallel,
      maxTurns: maxTurns,
      timeout: Duration(minutes: timeoutMin),
      validate: validate,
      change: change,
    );
  }

  final String model;
  final int reps;
  final List<String>? tasks;
  final List<String>? configs;
  final int parallel;
  final int maxTurns;
  final Duration timeout;
  final bool validate;

  /// Whether the tasks are changes to seeded code rather than fresh
  /// implementations.
  final bool change;

  String get tasksDir => change ? 'agents/changes' : 'agents/tasks';
  String get recordsPath =>
      change ? 'results/agents/changes.jsonl' : 'results/agents/runs.jsonl';
  String get outputsDir =>
      change ? 'results/agents/outputs/changes' : 'results/agents/outputs';
  String get logPrefix => change ? 'change-' : '';
}

List<RunRecord> _loadRecords(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const [];
  }
  return [
    for (final line in file.readAsLinesSync())
      if (line.isNotEmpty)
        RunRecord.fromJson(jsonDecode(line) as Map<String, Object?>),
  ];
}

Iterable<String> _names(Directory dir) =>
    (dir
        .listSync()
        .map((e) => e.uri.pathSegments.lastWhere((s) => s.isNotEmpty))
        .toList()
      ..sort());

Future<RunRecord> _run(
  String task,
  String config,
  int rep,
  _Options options,
  String root,
) async {
  final id = '$task-$config-$rep-${options.model}';
  final workdir = await _freshWorkdir(id, task, config, root, options, rep);
  final optionsText = File('$workdir/analysis_options.yaml').readAsStringSync();
  final prompt = File('${options.tasksDir}/$task/prompt.md').readAsStringSync();
  final solution = _solutionFile(prompt);
  final seedSource = File('$workdir/$solution').existsSync()
      ? File('$workdir/$solution').readAsStringSync()
      : null;

  final logFile = File('results/agents/logs/${options.logPrefix}$id.jsonl')
    ..createSync(recursive: true);
  final sink = logFile.openWrite();
  final process = await Process.start('claude', [
    '-p',
    prompt,
    '--model',
    options.model,
    '--output-format',
    'stream-json',
    '--verbose',
    '--permission-mode',
    'acceptEdits',
    '--allowedTools',
    _allowedTools,
    '--max-turns',
    '${options.maxTurns}',
    '--setting-sources',
    'project',
    '--no-session-persistence',
    '--disable-slash-commands',
    '--strict-mcp-config',
  ], workingDirectory: workdir);
  final timer = Timer(options.timeout, process.kill);
  // Without a closed stdin the CLI waits three seconds for piped input.
  await process.stdin.close();
  await Future.wait([process.stdout.pipe(sink), process.stderr.drain<void>()]);
  await process.exitCode;
  timer.cancel();
  final stream = logFile.readAsStringSync();
  final result = parseResult(stream);
  if (result.numTurns <= 1 && stream.contains('limit')) {
    // A subscription limit ends the CLI in one turn; the record would be
    // an empty run. Stop the batch, it resumes once the limit resets.
    throw StateError('usage limit hit on $id, stop and rerun later');
  }

  final optionsModified =
      File('$workdir/analysis_options.yaml').readAsStringSync() != optionsText;
  final tests = await _hiddenTests(task, workdir, options);
  final analyzeIssues = (await _analyze(workdir, root: null)).length;
  final full = await _analyze(workdir, root: root);
  File('$workdir/analysis_options.yaml').writeAsStringSync(optionsText);
  final fullByRule = <String, int>{};
  for (final d in full) {
    fullByRule.update(d.code, (n) => n + 1, ifAbsent: () => 1);
  }

  final libFiles = _dartFiles(Directory('$workdir/lib'));
  final outputDir = Directory(
    '${options.outputsDir}/$task/$config/$rep-${options.model}',
  );
  if (outputDir.existsSync()) {
    outputDir.deleteSync(recursive: true);
  }
  await _copyDir(Directory('$workdir/lib'), Directory('${outputDir.path}/lib'));
  final source = File('$workdir/$solution').existsSync()
      ? File('$workdir/$solution').readAsStringSync()
      : '';

  return RunRecord(
    task: task,
    config: config,
    rep: rep,
    model: options.model,
    subtype: result.subtype,
    numTurns: result.numTurns,
    durationMs: result.durationMs,
    costUsd: result.costUsd,
    inputTokens: result.inputTokens,
    outputTokens: result.outputTokens,
    testsPassed: tests.passed,
    testsTotal: tests.total,
    analyzeIssues: analyzeIssues,
    fullIssues: full.length,
    fullByRule: fullByRule,
    ignores: libFiles.fold(0, (n, f) => n + _ignores(f.readAsStringSync())),
    optionsModified: optionsModified,
    ruleMentions: ruleMentions(stream),
    loc: libFiles.fold(0, (n, f) => n + f.readAsLinesSync().length),
    source: source,
    changedLines: seedSource == null ? null : changedLines(seedSource, source),
  );
}

/// A fresh copy of the base app with the option set in place and
/// dependencies resolved. For a change task, the `lib/` a recorded run of
/// the seed config produced replaces the base app's, and the base task's
/// hidden tests become the project's tests.
Future<String> _freshWorkdir(
  String id,
  String task,
  String config,
  String root,
  _Options options,
  int rep,
) async {
  final workdir = Directory('${Directory.systemTemp.path}/lint_benchmark/$id');
  if (workdir.existsSync()) {
    workdir.deleteSync(recursive: true);
  }
  await _copyDir(Directory('agents/base'), workdir);
  final arm = Arm.parse(config);
  File('${workdir.path}/analysis_options.yaml').writeAsStringSync(
    File('agents/options/${arm.options}.yaml')
        .readAsStringSync()
        .replaceAll('{{root}}', root),
  );
  if (options.change) {
    final seed = Directory(
      'results/agents/outputs/$task/${arm.seed}/$rep-${options.model}/lib',
    );
    if (arm.seed == null || !seed.existsSync()) {
      throw StateError('no recorded output to seed $id from at ${seed.path}');
    }
    await _copyDir(seed, Directory('${workdir.path}/lib'));
    await _copyDir(
      Directory('agents/tasks/$task/tests'),
      Directory('${workdir.path}/test'),
    );
  }
  if (arm.withSkill) {
    // Installed the way `dart run skills@ get` installs it: the skill the
    // package ships under skills/, copied into the project's .claude/skills/.
    const skill = 'flutter_agent_lints-strict-dart';
    final source = Directory('$root/skills/$skill');
    if (!source.existsSync()) {
      // Silently running an empty skill arm would look like the skill made
      // no difference, which is the one result this must never fake.
      throw StateError('no skill to install at ${source.path}');
    }
    await _copyDir(source, Directory('${workdir.path}/.claude/skills/$skill'));
  }
  final pubGet = await Process.run('flutter', [
    'pub',
    'get',
  ], workingDirectory: workdir.path);
  if (pubGet.exitCode != 0) {
    throw StateError('flutter pub get failed in $workdir: ${pubGet.stderr}');
  }
  // pub get appends excludes to the options file; keep what it wrote so
  // the agent's edits can be told apart from pub's.
  return workdir.path;
}

/// The base task's hidden tests, plus the change's for a change task.
Future<({int passed, int total})> _hiddenTests(
  String task,
  String workdir,
  _Options options,
) async {
  await _copyDir(
    Directory('agents/tasks/$task/tests'),
    Directory('$workdir/test/hidden'),
  );
  if (options.change) {
    await _copyDir(
      Directory('agents/changes/$task/tests'),
      Directory('$workdir/test/hidden'),
    );
  }
  final result = await Process.run(
    'flutter',
    ['test', 'test/hidden', '--reporter', 'json'],
    workingDirectory: workdir,
    stdoutEncoding: utf8,
  );
  return countTests(result.stdout as String);
}

/// Diagnostics of `lib/` under the run's own options, or with [root] under
/// the full flutter_agent_lints options.
Future<List<Diagnostic>> _analyze(
  String workdir, {
  required String? root,
}) async {
  if (root != null) {
    File('$workdir/analysis_options.yaml')
        .writeAsStringSync('include: $root/lib/analysis_options.yaml\n');
  }
  final result = await Process.run(
    'dart',
    ['analyze', '--format=json', 'lib'],
    workingDirectory: workdir,
    stdoutEncoding: utf8,
  );
  final out = result.stdout as String;
  final start = out.indexOf('{');
  if (start < 0) {
    return const [];
  }
  return parseAnalyzeJson(out.substring(start), packageRoot: workdir);
}

Future<void> _validate(String task, String root, _Options options) async {
  final workdir = await _freshWorkdir(
    'validate-$task',
    task,
    options.change ? 'selected@flutter_lints' : 'selected',
    root,
    options,
    0,
  );
  await _copyDir(
    Directory('${options.tasksDir}/$task/reference'),
    Directory(workdir),
  );
  final tests = await _hiddenTests(task, workdir, options);
  final issues = (await _analyze(workdir, root: null)).length;
  stdout.writeln(
    '$task: reference passes ${tests.passed} of ${tests.total} hidden '
    'tests, $issues issues under selected',
  );
}

final _solutionPattern = RegExp(r'(?:Implement|Extend) `(lib/[a-z_]+\.dart)`');

String _solutionFile(String prompt) =>
    _solutionPattern.firstMatch(prompt)!.group(1)!;

final _ignorePattern = RegExp(r'//\s*ignore(_for_file)?:');

int _ignores(String source) => _ignorePattern.allMatches(source).length;

List<File> _dartFiles(Directory dir) => dir.existsSync()
    ? (dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path)))
    : const [];

Future<void> _copyDir(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entity in from.list(recursive: true)) {
    final relative = entity.path.substring(from.path.length + 1);
    if (entity is Directory) {
      await Directory('${to.path}/$relative').create(recursive: true);
    } else if (entity is File) {
      await File('${to.path}/$relative').create(recursive: true);
      await entity.copy('${to.path}/$relative');
    }
  }
}
