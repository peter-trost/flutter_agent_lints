import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the most recent search.
enum SearchStatus { idle, loading, success, error }

/// Debounces query changes and keeps the results of the latest query only.
class SearchModel extends ChangeNotifier {
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) : assert(!debounce.isNegative, 'debounce must not be negative'),
       // Wrapped so that a fetcher throwing synchronously is handled the same
       // way as one completing with an error.
       _fetcher = ((String query) =>
           Future<List<String>>.sync(() => fetcher(query))),
       _debounce = debounce;

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;
  bool _disposed = false;

  /// Identifies the latest fetch; responses carrying an older id are stale.
  int _fetchId = 0;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  /// Records [text] and schedules a fetch once no further change arrives for
  /// the debounce duration.
  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _timer?.cancel();
    _timer = null;

    if (text.isEmpty) {
      // Nothing to fetch: drop whatever is in flight and start over.
      _fetchId++;
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
    } else {
      _timer = Timer(_debounce, _startFetch);
    }
    notifyListeners();
  }

  void _startFetch() {
    _timer = null;
    if (_disposed) {
      return;
    }
    final int id = ++_fetchId;
    final String query = _query;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    unawaited(_fetch(id, query));
  }

  Future<void> _fetch(int id, String query) {
    return _fetcher(query).then(
      (List<String> value) {
        if (_isStale(id, query)) {
          return;
        }
        _status = SearchStatus.success;
        _results = List<String>.unmodifiable(value);
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_isStale(id, query)) {
          return;
        }
        _status = SearchStatus.error;
        _error = error;
        _results = const <String>[];
        notifyListeners();
      },
    );
  }

  bool _isStale(int id, String query) =>
      _disposed || id != _fetchId || query != _query;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
