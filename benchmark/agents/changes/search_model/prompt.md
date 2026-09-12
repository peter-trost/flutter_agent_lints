Extend `lib/search_model.dart` in this Flutter app. It already implements
`SearchModel`, and `test/search_model_test.dart` covers it; keep every
existing test passing. Add to the public API:

```dart
class SearchModel extends ChangeNotifier {
  void retry(); // re-runs the fetch for the current query after an error
}
```

Behavior:

- When `status` is `error`, `retry` starts a fetch for the current query at
  once, without the debounce: status becomes `loading` and listeners are
  notified, then the fetch completes the way any fetch does, into `success`
  or `error`.
- When `status` is anything else, or after `dispose`, `retry` does nothing.
- A query change while the retried fetch is in flight makes its response
  stale, so it is dropped like any stale response.

Finish when `dart analyze` reports no issues and `dart format .` changes
nothing. Do not edit `analysis_options.yaml` and do not add `ignore`
comments. You may add tests of your own under `test/`.
