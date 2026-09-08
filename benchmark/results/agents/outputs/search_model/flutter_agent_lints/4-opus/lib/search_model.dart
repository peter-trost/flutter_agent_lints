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

  /// Identifies the newest accepted query. A fetch whose token no longer
  /// matches belongs to a superseded query and its outcome is discarded.
  var _token = 0;
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
    _token++;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }
    final token = _token;
    _timer = Timer(_debounce, () => unawaited(_fetch(text, token)));
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Future<void> _fetch(String text, int token) async {
    _timer = null;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final found = List<String>.unmodifiable(await _fetcher(text));
      if (_disposed || token != _token) {
        return;
      }
      _status = SearchStatus.success;
      _results = found;
      _error = null;
    } on Object catch (e) {
      if (_disposed || token != _token) {
        return;
      }
      _status = SearchStatus.error;
      _results = const <String>[];
      _error = e;
    }
    notifyListeners();
  }
}
