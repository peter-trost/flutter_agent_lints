import 'dart:async';
import 'dart:collection';

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
  final _results = <String>[];

  Timer? _timer;
  var _query = '';
  var _status = SearchStatus.idle;
  var _requestId = 0;
  var _disposed = false;
  Object? _error;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => UnmodifiableListView(_results);

  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _timer?.cancel();
    _timer = null;
    if (text.isEmpty) {
      // Invalidating the id drops whatever is still in flight for the
      // query that was just replaced.
      _requestId++;
      _status = SearchStatus.idle;
      _error = null;
      _results.clear();
      notifyListeners();
      return;
    }
    notifyListeners();
    _timer = Timer(_debounce, () => unawaited(_fetch(text)));
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Future<void> _fetch(String text) async {
    _timer = null;
    final id = ++_requestId;
    _status = SearchStatus.loading;
    notifyListeners();
    try {
      final values = await _fetcher(text);
      if (_isStale(id, text)) {
        return;
      }
      _results
        ..clear()
        ..addAll(values);
      _status = SearchStatus.success;
      _error = null;
      notifyListeners();
    } on Object catch (failure) {
      if (_isStale(id, text)) {
        return;
      }
      _results.clear();
      _status = SearchStatus.error;
      _error = failure;
      notifyListeners();
    }
  }

  bool _isStale(int id, String text) =>
      _disposed || id != _requestId || text != _query;
}
