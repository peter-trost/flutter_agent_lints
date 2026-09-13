import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SearchFetcher = Future<List<String>> Function(String query);

enum SearchStatus { idle, loading, success, error }

class SearchModel extends ChangeNotifier {
  new({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) : this._internal(fetcher, debounce);

  new _internal(this._fetcher, this._debounce);

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;
  var _status = SearchStatus.idle;
  var _query = '';
  List<String> _results = const [];
  Object? _error;

  /// Identifies the most recent request; a fetch whose generation is stale
  /// has been superseded and its outcome is dropped.
  var _generation = 0;
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
    final generation = ++_generation;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
    } else {
      _timer = Timer(_debounce, () => unawaited(_fetch(text, generation)));
    }
    notifyListeners();
  }

  Future<void> _fetch(String text, int generation) async {
    if (_isDisposed || generation != _generation) {
      return;
    }
    _timer = null;
    _status = SearchStatus.loading;
    notifyListeners();
    try {
      final results = await _fetcher(text);
      if (_isDisposed || generation != _generation) {
        return;
      }
      _results = List.unmodifiable(results);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_isDisposed || generation != _generation) {
        return;
      }
      _results = const [];
      _error = error;
      _status = SearchStatus.error;
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
