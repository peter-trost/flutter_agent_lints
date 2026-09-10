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

  /// Identifies the newest fetch that was started. A response carrying an
  /// older id belongs to a query that is no longer current and is dropped,
  /// whatever the order in which the fetches complete.
  var _currentFetch = 0;
  var _disposed = false;

  Timer? _timer;
  var _status = SearchStatus.idle;
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
    // Anything still in flight was started for an older query.
    _currentFetch++;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
    } else {
      _status = SearchStatus.loading;
      _error = null;
      _timer = Timer(_debounce, () => _start(text));
    }
    notifyListeners();
  }

  void _start(String text) {
    _timer = null;
    if (_disposed) {
      return;
    }
    unawaited(_fetch(++_currentFetch, text));
  }

  Future<void> _fetch(int id, String text) async {
    try {
      final values = await _fetcher(text);
      if (_disposed || id != _currentFetch) {
        return;
      }
      _results = List<String>.unmodifiable(values);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_disposed || id != _currentFetch) {
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
    // Drops every response that is still in flight.
    _currentFetch++;
    super.dispose();
  }
}
