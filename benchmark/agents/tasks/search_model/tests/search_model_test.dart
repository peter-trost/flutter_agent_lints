import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_app/search_model.dart';

void main() {
  testWidgets('fetches once after the debounce with the latest text', (
    tester,
  ) async {
    final queries = <String>[];
    final model = SearchModel(
      fetcher: (q) async {
        queries.add(q);
        return ['$q!'];
      },
    );
    addTearDown(model.dispose);

    model.onQueryChanged('a');
    expect(model.query, 'a');
    await tester.pump(const Duration(milliseconds: 100));
    model.onQueryChanged('ab');
    await tester.pump(const Duration(milliseconds: 200));
    expect(queries, isEmpty);
    expect(model.status, SearchStatus.idle);

    await tester.pump(const Duration(milliseconds: 100));
    expect(queries, ['ab']);
    expect(model.status, SearchStatus.success);
    expect(model.results, ['ab!']);
  });

  testWidgets('notifies on change, loading and success', (tester) async {
    var notifications = 0;
    final model = SearchModel(fetcher: (q) async => [q]);
    addTearDown(model.dispose);
    model
      ..addListener(() => notifications++)
      ..onQueryChanged('x');
    expect(notifications, 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(notifications, greaterThanOrEqualTo(2));
    expect(model.status, SearchStatus.success);
  });

  testWidgets('a stale response never overwrites a newer one', (tester) async {
    final completers = <String, Completer<List<String>>>{};
    final model = SearchModel(
      fetcher: (q) => (completers[q] = Completer<List<String>>()).future,
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);

    model.onQueryChanged('first');
    await tester.pump(const Duration(milliseconds: 1));
    model.onQueryChanged('second');
    await tester.pump(const Duration(milliseconds: 1));
    expect(completers.keys, ['first', 'second']);
    expect(model.status, SearchStatus.loading);

    completers['second']!.complete(['2']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.results, ['2']);
    expect(model.status, SearchStatus.success);

    var notified = false;
    model.addListener(() => notified = true);
    completers['first']!.complete(['1']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.results, ['2']);
    expect(notified, isFalse);
  });

  testWidgets('a fetch error becomes the error state', (tester) async {
    final model = SearchModel(
      fetcher: (q) async => throw StateError('boom'),
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);

    model.onQueryChanged('x');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.error);
    expect(model.error, isA<StateError>());
    expect(model.results, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty query clears state and drops in-flight results', (
    tester,
  ) async {
    final completer = Completer<List<String>>();
    var calls = 0;
    final model = SearchModel(
      fetcher: (q) {
        calls++;
        return completer.future;
      },
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);

    model.onQueryChanged('x');
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.loading);
    model.onQueryChanged('');
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.status, SearchStatus.idle);
    completer.complete(['late']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(model.results, isEmpty);
    expect(model.status, SearchStatus.idle);
    expect(calls, 1);
  });

  testWidgets('results are unmodifiable', (tester) async {
    final model = SearchModel(
      fetcher: (q) async => [q],
      debounce: Duration.zero,
    );
    addTearDown(model.dispose);
    model.onQueryChanged('x');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(() => model.results.add('y'), throwsUnsupportedError);
  });

  testWidgets('dispose cancels the debounce and silences listeners', (
    tester,
  ) async {
    var calls = 0;
    SearchModel(
        fetcher: (q) async {
          calls++;
          return [q];
        },
      )
      ..onQueryChanged('x')
      ..dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 0);
  });

  testWidgets('no notification after dispose while a fetch is in flight', (
    tester,
  ) async {
    final completer = Completer<List<String>>();
    final model = SearchModel(
      fetcher: (q) => completer.future,
      debounce: Duration.zero,
    )..onQueryChanged('x');
    await tester.pump(const Duration(milliseconds: 1));
    model.dispose();
    completer.complete(['x']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.takeException(), isNull);
  });
}
