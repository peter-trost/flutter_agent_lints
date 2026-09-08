import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search.
enum SearchStatus { idle, loading, success, error }

/// Debounces query changes and keeps the results of the latest query only.
class SearchModel extends ChangeNotifier {
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) : _searchFetcher = fetcher,
       _debounceDelay = debounce;

  final SearchFetcher _searchFetcher;
  final Duration _debounceDelay;

  Timer? _timer;

  /// Identifies the fetch that may still write to this model. Every change of
  /// the query invalidates whatever was in flight before it.
  int _fetchId = 0;
  bool _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _timer?.cancel();
    _timer = null;
    _fetchId++;

    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    _timer = Timer(_debounceDelay, () {
      _timer = null;
      unawaited(_fetch(text, _fetchId));
    });
  }

  Future<void> _fetch(String text, int id) async {
    if (_disposed || id != _fetchId) {
      return;
    }
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final List<String> fetched = await _searchFetcher(text);
      if (_disposed || id != _fetchId) {
        return;
      }
      _results = List<String>.unmodifiable(fetched);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_disposed || id != _fetchId) {
        return;
      }
      _results = const <String>[];
      _error = error;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _fetchId++;
    super.dispose();
  }
}
