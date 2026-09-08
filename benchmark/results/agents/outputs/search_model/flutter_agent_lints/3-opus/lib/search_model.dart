import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SearchFetcher = Future<List<String>> Function(String query);

enum SearchStatus { idle, loading, success, error }

/// Debounced search state: the latest query wins, stale responses are dropped.
class SearchModel extends ChangeNotifier {
  new({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;

  /// Identifies the newest request; a response with a stale id is discarded.
  var _requestId = 0;
  var _disposed = false;

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
    // Any response still in flight belongs to an earlier query now.
    final id = ++_requestId;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
    } else {
      _timer = Timer(_debounce, () {
        unawaited(_fetch(text, id));
      });
    }
    notifyListeners();
  }

  Future<void> _fetch(String text, int id) async {
    _timer = null;
    if (_disposed || id != _requestId) {
      return;
    }
    _status = SearchStatus.loading;
    notifyListeners();
    try {
      final values = await _fetcher(text);
      if (_disposed || id != _requestId) {
        return;
      }
      _results = List<String>.unmodifiable(values);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_disposed || id != _requestId) {
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
    super.dispose();
  }
}
