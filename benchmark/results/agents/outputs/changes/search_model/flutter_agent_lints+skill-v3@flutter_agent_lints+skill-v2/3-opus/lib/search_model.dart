import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SearchFetcher = Future<List<String>> Function(String query);

enum SearchStatus { idle, loading, success, error }

class SearchModel extends ChangeNotifier {
  new({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  var _status = SearchStatus.idle;
  var _query = '';
  var _results = const <String>[];
  Object? _error;
  Timer? _debounceTimer;

  // Identifies the query a response belongs to. Every query change bumps it,
  // so a response whose id no longer matches is stale and is dropped.
  var _queryId = 0;
  var _isDisposed = false;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_isDisposed || text == _query) {
      return;
    }
    _query = text;
    _queryId++;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
    } else {
      _debounceTimer = Timer(_debounce, () => _startFetch(text));
    }
    notifyListeners();
  }

  /// Re-runs the fetch for the current query, skipping the debounce. Does
  /// nothing unless the last fetch failed.
  void retry() {
    if (_isDisposed || _status != SearchStatus.error) {
      return;
    }
    // A debounce may be pending for a query typed since the failure; the
    // retry takes its place so the query is fetched exactly once.
    _debounceTimer?.cancel();
    _startFetch(_query);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }

  void _startFetch(String text) {
    _debounceTimer = null;
    if (_isDisposed) {
      return;
    }
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    unawaited(_fetch(_queryId, text));
  }

  Future<void> _fetch(int queryId, String text) async {
    try {
      final values = await _fetcher(text);
      if (_isDisposed || queryId != _queryId) {
        return;
      }
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(values);
      _error = null;
    } on Object catch (error) {
      if (_isDisposed || queryId != _queryId) {
        return;
      }
      _status = SearchStatus.error;
      _results = const [];
      _error = error;
    }
    notifyListeners();
  }
}
