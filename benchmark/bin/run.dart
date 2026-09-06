import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:lint_benchmark/src/diagnostics.dart';
import 'package:lint_benchmark/src/diff.dart';
import 'package:lint_benchmark/src/options.dart';
import 'package:lint_benchmark/src/score.dart';
import 'package:yaml/yaml.dart';

/// Mines the corpus repositories for bug-fix commits and scores each option
/// set on them. Results land in `results/<repo>.json`, one commit at a time,
/// so an interrupted run resumes where it stopped.
///
/// Usage: dart run bin/run.dart [--limit N] [repo ...]
Future<void> main(List<String> args) async {
  var limit = 1 << 30;
  final names = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--limit') {
      limit = int.parse(args[++i]);
    } else {
      names.add(args[i]);
    }
  }

  final packageRoot = Directory.current.parent.path;
  final optionSets = {
    'flutter_lints': flattenOptions(
      'package:flutter_lints/flutter.yaml',
      read: _readPackageUri,
    ),
    'flutter_agent_lints': 'include: $packageRoot/lib/analysis_options.yaml\n',
  };
  final generated = _generatedSuffixes(
    '$packageRoot/lib/analysis_options.yaml',
  );

  final corpus = loadYaml(File('corpus.yaml').readAsStringSync()) as YamlMap;
  for (final entry in (corpus['repos'] as YamlList).cast<YamlMap>()) {
    final repo = _Repo(entry);
    if (names.isNotEmpty && !names.contains(repo.name)) {
      continue;
    }
    await _runRepo(repo, optionSets, generated, limit);
  }
}

const _maxFiles = 5;
const _maxFixLines = 200;
const _fixPattern = r'\b(fix|fixes|fixed|bug|crash)\b';

class _Repo {
  new(YamlMap entry)
    : name = entry['name'] as String,
      url = entry['url'] as String,
      path = entry['path'] as String,
      since = entry['since'].toString();

  final String name;
  final String url;
  final String path;
  final String since;

  String get checkout => '.cache/$name';
  String get package => path == '.' ? checkout : '$checkout/$path';
  String get pathspec => path == '.' ? 'lib/*.dart' : '$path/lib/*.dart';
}

Future<void> _runRepo(
  _Repo repo,
  Map<String, String> optionSets,
  List<String> generated,
  int limit,
) async {
  if (!Directory(repo.checkout).existsSync()) {
    await _git(['clone', '--filter=blob:none', repo.url, repo.checkout]);
  } else {
    await _git(['-C', repo.checkout, 'fetch', '-q']);
  }

  final results = _Results.load(repo);
  final candidates = (await _git([
    '-C',
    repo.checkout,
    'log',
    '--no-merges',
    'origin/HEAD',
    '--since=${repo.since}',
    '-i',
    '-P',
    '--grep=$_fixPattern',
    '--diff-filter=M',
    '--format=%H %s',
    '--',
    repo.pathspec,
  ])).trim().split('\n').where((l) => l.isNotEmpty).take(limit);

  for (final line in candidates) {
    final sha = line.substring(0, 40);
    final subject = line.substring(41);
    if (results.has(sha)) {
      continue;
    }
    stdout.write('${repo.name} ${sha.substring(0, 7)} $subject: ');
    try {
      final scored = await _scoreCommit(repo, sha, optionSets, generated);
      if (scored == null) {
        continue;
      }
      results.add(sha, subject, scored);
      stdout.writeln(
        scored.scores.entries
            .map((e) => '${e.key} ${e.value.hitLines}/${e.value.fixLines}')
            .join(', '),
      );
    } on _Skip catch (e) {
      results.skip(sha, e.reason);
      stdout.writeln('skipped, ${e.reason}');
    }
  }
}

class _Scored {
  const new(this.files, this.scores);

  final List<String> files;
  final Map<String, CommitScore> scores;
}

Future<_Scored?> _scoreCommit(
  _Repo repo,
  String sha,
  Map<String, String> optionSets,
  List<String> generated,
) async {
  final touched = (await _git([
    '-C',
    repo.checkout,
    'diff',
    '--name-only',
    '--diff-filter=M',
    '$sha^',
    sha,
    '--',
    repo.pathspec,
  ])).trim().split('\n').where((f) => f.isNotEmpty).toList();
  final files = touched
      .where((f) => !generated.any(f.endsWith))
      .map((f) => repo.path == '.' ? f : f.substring(repo.path.length + 1))
      .toList();
  if (files.isEmpty) {
    throw _Skip('only generated files');
  }
  if (files.length > _maxFiles) {
    throw _Skip('${files.length} files');
  }

  final changes = <String, ChangedLines>{};
  for (final file in files) {
    final diff = await _git([
      '-C',
      repo.checkout,
      'diff',
      '-U0',
      '$sha^',
      sha,
      '--',
      if (repo.path == '.') file else '${repo.path}/$file',
    ]);
    changes[file] = changedLinesFromUnifiedDiff(diff);
  }
  final fixLines = changes.values.fold(0, (n, c) => n + c.before.length);
  if (fixLines == 0) {
    throw _Skip('only additions');
  }
  if (fixLines > _maxFixLines) {
    throw _Skip('$fixLines fixed lines');
  }

  await _checkout(repo, '$sha^');
  final lineCounts = {
    for (final file in files)
      file: File('${repo.package}/$file').readAsLinesSync().length,
  };
  final before = <String, List<Diagnostic>>{};
  for (final set in optionSets.entries) {
    before[set.key] = await _analyze(repo, set.value, files);
  }

  final anyCandidate = before.entries.any(
    (e) => e.value.any(
      (d) =>
          d.countsForOptions &&
          (changes[d.file]?.before.contains(d.line) ?? false),
    ),
  );
  final after = <String, List<Diagnostic>>{};
  if (anyCandidate) {
    await _checkout(repo, sha);
    for (final set in optionSets.entries) {
      after[set.key] = await _analyze(repo, set.value, files);
    }
  }

  return _Scored(files, {
    for (final set in optionSets.keys)
      set: scoreCommit(
        changes: changes,
        before: before[set]!,
        after: after[set] ?? const [],
        lineCounts: lineCounts,
      ),
  });
}

Future<void> _checkout(_Repo repo, String ref) async {
  await _git(['-C', repo.checkout, 'checkout', '-q', '-f', ref]);
  await _git(['-C', repo.checkout, 'clean', '-q', '-fd']);
  if (await _pubGet(repo)) {
    return;
  }
  // Old lockfiles pin packages the installed SDK no longer ships with.
  final lock = File('${repo.package}/pubspec.lock');
  if (lock.existsSync()) {
    lock.deleteSync();
    if (await _pubGet(repo)) {
      return;
    }
  }
  throw _Skip('pub get failed at ${ref.substring(0, 7)}');
}

Future<bool> _pubGet(_Repo repo) async {
  final result = await Process.run('flutter', [
    'pub',
    'get',
  ], workingDirectory: repo.package);
  return result.exitCode == 0;
}

Future<List<Diagnostic>> _analyze(
  _Repo repo,
  String options,
  List<String> files,
) async {
  File('${repo.package}/analysis_options.yaml').writeAsStringSync(options);
  // The dart tool occasionally dies before reporting, on its own analytics
  // upload for one; a second attempt is cheap next to a lost commit.
  ProcessResult? result;
  for (var attempt = 0; attempt < 2; attempt++) {
    result = await Process.run(
      'dart',
      ['analyze', '--format=json', ...files],
      workingDirectory: repo.package,
      stdoutEncoding: utf8,
    );
    if ((result.stdout as String).contains('{')) {
      break;
    }
  }
  final out = result!.stdout as String;
  final start = out.indexOf('{');
  if (start < 0) {
    final reason = (result.stderr as String).trim().split('\n').first;
    throw _Skip('analyzer gave no report: $reason');
  }
  return parseAnalyzeJson(
    out.substring(start),
    packageRoot: Directory(repo.package).absolute.path,
  );
}

class _Results {
  new(this.repo, this.json);

  factory load(_Repo repo) {
    final file = File('results/${repo.name}.json');
    final json = file.existsSync()
        ? jsonDecode(file.readAsStringSync()) as Map<String, Object?>
        : <String, Object?>{
            'repo': repo.name,
            'url': repo.url,
            'path': repo.path,
            'since': repo.since,
            'commits': <Object?>[],
            'skipped': <Object?>[],
          };
    return _Results(repo, json);
  }

  final _Repo repo;
  final Map<String, Object?> json;

  List<Object?> get _commits => json['commits']! as List<Object?>;
  List<Object?> get _skipped => json['skipped']! as List<Object?>;

  bool has(String sha) => [
    ..._commits,
    ..._skipped,
  ].any((c) => (c! as Map<String, Object?>)['sha'] == sha);

  void add(String sha, String subject, _Scored scored) {
    _commits.add({
      'sha': sha,
      'subject': subject,
      'files': scored.files,
      'scores': scored.scores.map((k, v) => MapEntry(k, v.toJson())),
    });
    _save();
  }

  void skip(String sha, String reason) {
    _skipped.add({'sha': sha, 'reason': reason});
    _save();
  }

  void _save() {
    File('results/${repo.name}.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
  }
}

class _Skip implements Exception {
  new(this.reason);

  final String reason;
}

Future<String> _git(List<String> args) async {
  final result = await Process.run('git', args, stdoutEncoding: utf8);
  if (result.exitCode != 0) {
    throw _Skip('git ${args.join(' ')}: ${result.stderr}');
  }
  return result.stdout as String;
}

String _readPackageUri(String uri) {
  final resolved = Isolate.resolvePackageUriSync(Uri.parse(uri));
  if (resolved == null) {
    throw StateError('cannot resolve $uri');
  }
  return File.fromUri(resolved).readAsStringSync();
}

/// The `**/*.x.dart` exclude patterns of the option file, as suffixes.
List<String> _generatedSuffixes(String optionsPath) {
  final doc = loadYaml(File(optionsPath).readAsStringSync()) as YamlMap;
  final excludes = (doc['analyzer'] as YamlMap)['exclude'] as YamlList;
  return [
    for (final pattern in excludes.cast<String>())
      pattern.replaceFirst('**/*', ''),
  ];
}
