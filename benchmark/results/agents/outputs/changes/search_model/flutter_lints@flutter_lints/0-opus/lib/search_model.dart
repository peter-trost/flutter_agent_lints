import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search.
enum SearchStatus { idle, loading, success, error }

/// Runs debounced searches through a [SearchFetcher] and exposes their state.
class SearchModel extends ChangeNotifier {
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) : _runSearch = fetcher,
       _debounceDuration = debounce;

  final SearchFetcher _runSearch;
  final Duration _debounceDuration;

  Timer? _timer;
  bool _disposed = false;

  /// Identifies the search a pending timer or an in-flight fetch belongs to.
  ///
  /// Bumped whenever the query changes or the model is disposed, so that
  /// anything started for an earlier query can be recognised and dropped.
  int _generation = 0;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  /// Records [text] as the current query and schedules a fetch for it.
  ///
  /// The fetch runs once the debounce has elapsed without another change.
  /// Text equal to the current query is ignored.
  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }

    _query = text;
    _timer?.cancel();
    _timer = null;
    // Anything already scheduled or in flight belongs to an older query.
    _generation++;

    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    final int generation = _generation;
    _timer = Timer(_debounceDuration, () {
      _timer = null;
      unawaited(_fetch(text, generation));
    });
    notifyListeners();
  }

  /// Re-runs the fetch for the current query straight away.
  ///
  /// Only takes effect while [status] is [SearchStatus.error]; the debounce is
  /// skipped, so the status becomes [SearchStatus.loading] before this returns.
  void retry() {
    if (_disposed || _status != SearchStatus.error) {
      return;
    }

    _timer?.cancel();
    _timer = null;
    // Supersede anything scheduled or in flight for the previous attempt.
    _generation++;
    unawaited(_fetch(_query, _generation));
  }

  Future<void> _fetch(String text, int generation) async {
    if (_disposed || generation != _generation) {
      return;
    }

    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final List<String> results = await _runSearch(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(results);
      _error = null;
    } on Object catch (error) {
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.error;
      _results = const <String>[];
      _error = error;
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _generation++;
    super.dispose();
  }
}
