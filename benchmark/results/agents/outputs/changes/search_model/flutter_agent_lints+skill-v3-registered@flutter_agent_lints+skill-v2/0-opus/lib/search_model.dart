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
  var _fetchId = 0;
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
    _debounceTimer?.cancel();
    _debounceTimer = null;
    // Whatever is in flight belongs to an older query.
    _fetchId++;
    if (text.isEmpty) {
      // Nothing to fetch.
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
      notifyListeners();
      return;
    }
    notifyListeners();
    _debounceTimer = Timer(_debounce, _startFetch);
  }

  void retry() {
    if (_isDisposed || _status != SearchStatus.error) {
      return;
    }
    // The retry replaces any pending debounce, and fetches the current query
    // straight away.
    _debounceTimer?.cancel();
    _startFetch();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    super.dispose();
  }

  void _startFetch() {
    _debounceTimer = null;
    if (_isDisposed) {
      return;
    }
    _status = SearchStatus.loading;
    notifyListeners();
    unawaited(_fetch(++_fetchId, _query));
  }

  Future<void> _fetch(int fetchId, String query) async {
    try {
      final results = await _fetcher(query);
      if (_isDisposed || fetchId != _fetchId) {
        return;
      }
      _results = List.unmodifiable(results);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_isDisposed || fetchId != _fetchId) {
        return;
      }
      _results = const [];
      _error = error;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }
}
