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

  Timer? _timer;
  var _status = SearchStatus.idle;
  var _query = '';
  var _results = const <String>[];
  Object? _error;

  // Identifies the most recent fetch. Every new fetch, and every reset to
  // idle, takes a fresh number, so a response whose number no longer matches
  // belongs to a query that is no longer current and is dropped.
  var _currentRequest = 0;
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
    _timer?.cancel();
    _timer = null;

    if (text.isEmpty) {
      _currentRequest++;
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    _timer = Timer(_debounce, () => _startFetch(text));
  }

  void _startFetch(String text) {
    _timer = null;
    if (_isDisposed) {
      return;
    }
    _currentRequest++;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    unawaited(_fetch(text, _currentRequest));
  }

  Future<void> _fetch(String text, int request) async {
    try {
      final fetched = await _fetcher(text);
      if (_isDisposed || request != _currentRequest) {
        return;
      }
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(fetched);
      _error = null;
    } on Object catch (thrown) {
      if (_isDisposed || request != _currentRequest) {
        return;
      }
      _status = SearchStatus.error;
      _results = const [];
      _error = thrown;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
