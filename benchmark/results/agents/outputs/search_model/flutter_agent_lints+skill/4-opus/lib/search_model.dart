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

  /// Identifies the fetch a response belongs to. Every accepted query change
  /// bumps it, so a response that carries an older value is stale.
  var _requestId = 0;
  var _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  var _query = '';
  List<String> _results = const [];
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
    // Anything still in flight was fetched for a query that is no longer
    // current, so its response must not land.
    _requestId++;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
    } else {
      _timer = Timer(_debounce, () => unawaited(_fetch(text)));
    }
    notifyListeners();
  }

  Future<void> _fetch(String text) async {
    if (_disposed) {
      return;
    }
    _timer = null;
    final id = _requestId;
    _status = SearchStatus.loading;
    notifyListeners();
    try {
      final fetched = await _fetcher(text);
      if (_disposed || id != _requestId) {
        return;
      }
      _results = List.unmodifiable(fetched);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (e) {
      if (_disposed || id != _requestId) {
        return;
      }
      _results = const [];
      _error = e;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
