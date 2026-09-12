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
  Object? _error;
  var _status = SearchStatus.idle;
  var _query = '';
  var _results = const <String>[];

  // Incremented on every accepted query change, so a fetch that resolves for
  // a token other than the current one is known to be stale.
  var _token = 0;
  var _disposed = false;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _token++;
    _timer?.cancel();
    _timer = null;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
    } else {
      final token = _token;
      _timer = Timer(_debounce, () {
        unawaited(_fetch(text, token));
      });
    }
    notifyListeners();
  }

  Future<void> _fetch(String text, int token) async {
    if (_disposed || token != _token) {
      return;
    }
    _status = SearchStatus.loading;
    notifyListeners();
    try {
      final found = await _fetcher(text);
      if (_disposed || token != _token) {
        return;
      }
      _results = List<String>.unmodifiable(found);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (e) {
      if (_disposed || token != _token) {
        return;
      }
      _results = const <String>[];
      _error = e;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }
}
