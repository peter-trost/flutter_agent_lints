Implement `lib/search_model.dart` in this Flutter app. It must export exactly
this public API:

```dart
typedef SearchFetcher = Future<List<String>> Function(String query);

enum SearchStatus { idle, loading, success, error }

class SearchModel extends ChangeNotifier {
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  });

  SearchStatus get status;
  String get query;         // the latest text passed to onQueryChanged
  List<String> get results; // unmodifiable
  Object? get error;        // the error of the latest failed fetch, else null

  void onQueryChanged(String text);
}
```

Behavior:

- `onQueryChanged` stores the text and notifies listeners at once. A fetch
  starts only after `debounce` has passed without another change, and it
  is called with the latest text. Text equal to the current query starts
  nothing.
- An empty query fetches nothing: status becomes `idle`, results and error
  are cleared, and any result still in flight for an earlier query is
  dropped.
- While a fetch is in flight, status is `loading`. When it completes for
  the query that is still current, status is `success`, `results` holds
  what it returned, and listeners are notified. A response for a query that
  is no longer current is dropped without notifying, whatever the order in
  which fetches complete: stale results never overwrite newer ones.
- When the current fetch throws, status is `error`, `error` holds the
  thrown object, results are cleared, and listeners are notified. Nothing
  escapes to the caller of `onQueryChanged`.
- After `dispose`, no fetch starts, no listener is notified, and pending
  timers are cancelled.

Finish when `dart analyze` reports no issues and `dart format .` changes
nothing. Do not edit `analysis_options.yaml` and do not add `ignore`
comments. You may add tests of your own under `test/`.
