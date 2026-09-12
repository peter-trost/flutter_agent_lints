import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The lifecycle of the latest search a [SearchModel] cares about.
enum SearchStatus { idle, loading, success, error }

/// Debounces query changes and exposes the state of the latest search.
class SearchModel extends ChangeNotifier {
  new({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  /// Identifies the newest piece of work. Every change to [query] and
  /// [dispose] bump it, so a response carrying an older token is stale.
  var _token = 0;
  Timer? _timer;
  var _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  var _query = '';
  var _results = const <String>[];
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
    _token++;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
    } else {
      _timer = Timer(_debounce, _startFetch);
    }
    notifyListeners();
  }

  /// Re-runs the fetch for the current query, skipping the debounce. Does
  /// nothing unless the latest search ended in an error.
  void retry() {
    if (_disposed || _status != SearchStatus.error) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _token++;
    _startFetch();
  }

  @override
  void dispose() {
    _disposed = true;
    _token++;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _startFetch() {
    _timer = null;
    if (_disposed) {
      return;
    }
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    unawaited(_fetch(_query, _token));
  }

  Future<void> _fetch(String text, int token) async {
    try {
      final results = await _fetcher(text);
      if (_disposed || token != _token) {
        return;
      }
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(results);
      _error = null;
    } on Object catch (error) {
      if (_disposed || token != _token) {
        return;
      }
      _status = SearchStatus.error;
      _results = const <String>[];
      _error = error;
    }
    notifyListeners();
  }
}
