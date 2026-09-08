import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results matching [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the search for the current query.
enum SearchStatus {
  /// No query is being searched for.
  idle,

  /// A fetch for the current query is in flight.
  loading,

  /// The fetch for the current query completed.
  success,

  /// The fetch for the current query threw.
  error,
}

/// Searches with [SearchFetcher] for the text passed to [onQueryChanged],
/// debouncing the calls and discarding results that arrive for a query that
/// is no longer current.
class SearchModel extends ChangeNotifier {
  /// Creates a model that searches with `fetcher` once `debounce` has passed
  /// without a further change of the query.
  new({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;

  /// Identifies the latest query, so that a response of an earlier one can be
  /// recognised and dropped.
  var _requestId = 0;

  var _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  var _query = '';
  var _results = const <String>[];
  Object? _error;

  /// The state of the search for [query].
  SearchStatus get status => _status;

  /// The latest text passed to [onQueryChanged].
  String get query => _query;

  /// The results of the latest successful fetch, empty otherwise.
  ///
  /// The list is unmodifiable.
  List<String> get results => _results;

  /// The object thrown by the latest failed fetch, `null` otherwise.
  Object? get error => _error;

  /// Stores [text] as the current [query] and schedules a fetch for it.
  ///
  /// Text equal to the current [query] does nothing. An empty text clears the
  /// results and the error and leaves the status [SearchStatus.idle].
  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _timer?.cancel();
    _timer = null;
    // Any response still in flight is now for an earlier query.
    _requestId++;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
    } else {
      final requestId = _requestId;
      _timer = Timer(_debounce, () => unawaited(_fetch(text, requestId)));
    }
    notifyListeners();
  }

  Future<void> _fetch(String text, int requestId) async {
    if (_isStale(requestId)) {
      return;
    }
    _timer = null;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final values = await _fetcher(text);
      if (_isStale(requestId)) {
        return;
      }
      _results = List<String>.unmodifiable(values);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_isStale(requestId)) {
        return;
      }
      _results = const <String>[];
      _error = error;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  bool _isStale(int requestId) => _disposed || requestId != _requestId;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
