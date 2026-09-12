import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/search_model.dart';

void main() {
  testWidgets('retry after an error fetches the same query at once', (
    tester,
  ) async {
    final queries = <String>[];
    var fail = true;
    final model = SearchModel(
      fetcher: (q) async {
        queries.add(q);
        if (fail) {
          throw StateError('down');
        }
        return ['$q!'];
      },
    );
    addTearDown(model.dispose);
    model.onQueryChanged('a');
    await tester.pump(const Duration(milliseconds: 300));
    expect(model.status, SearchStatus.error);
    expect(queries, ['a']);

    fail = false;
    model.retry();
    expect(model.status, SearchStatus.loading);
    await tester.pump(const Duration(milliseconds: 1));
    expect(queries, ['a', 'a']);
    expect(model.status, SearchStatus.success);
    expect(model.results, ['a!']);
    expect(model.error, isNull);
  });

  testWidgets('retry notifies on loading and on completion', (tester) async {
    var fail = true;
    final model = SearchModel(
      fetcher: (q) async {
        if (fail) {
          throw StateError('down');
        }
        return [q];
      },
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);
    model.onQueryChanged('a');
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.error);

    var notifications = 0;
    model.addListener(() => notifications++);
    fail = false;
    model.retry();
    expect(notifications, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(notifications, 2);
    expect(model.status, SearchStatus.success);
  });

  testWidgets('retry does nothing unless the status is error', (tester) async {
    var calls = 0;
    final completer = Completer<List<String>>();
    final model = SearchModel(
      fetcher: (q) {
        calls++;
        return completer.future;
      },
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);
    model.retry();
    expect(calls, 0);
    expect(model.status, SearchStatus.idle);

    model.onQueryChanged('a');
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.loading);
    model.retry();
    expect(calls, 1);

    completer.complete(['a']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.success);
    model.retry();
    expect(calls, 1);
  });

  testWidgets('a retried response is stale once the query changed', (
    tester,
  ) async {
    final completers = <Completer<List<String>>>[];
    var first = true;
    final model = SearchModel(
      fetcher: (q) {
        if (first) {
          first = false;
          return Future<List<String>>.error(StateError('down'));
        }
        final completer = Completer<List<String>>();
        completers.add(completer);
        return completer.future;
      },
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);
    model.onQueryChanged('a');
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.error);

    model
      ..retry()
      ..onQueryChanged('ab');
    await tester.pump(const Duration(milliseconds: 1));
    expect(completers, hasLength(2));
    completers[0].complete(['a!']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.results, isEmpty);
    expect(model.status, SearchStatus.loading);
    completers[1].complete(['ab!']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.results, ['ab!']);
  });

  testWidgets('a retry that fails again reports the new error', (tester) async {
    var attempt = 0;
    final model = SearchModel(
      fetcher: (q) async => throw StateError('down ${++attempt}'),
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);
    model.onQueryChanged('a');
    await tester.pump(const Duration(milliseconds: 1));
    model.retry();
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.error);
    expect(
      model.error,
      isA<StateError>().having((e) => e.message, 'message', 'down 2'),
    );
  });

  testWidgets('retry after dispose fetches nothing', (tester) async {
    var calls = 0;
    final model = SearchModel(
      fetcher: (q) async {
        calls++;
        throw StateError('down');
      },
      debounce: Duration.zero,
    )..onQueryChanged('a');
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.error);
    model
      ..dispose()
      ..retry();
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 1);
  });
}
