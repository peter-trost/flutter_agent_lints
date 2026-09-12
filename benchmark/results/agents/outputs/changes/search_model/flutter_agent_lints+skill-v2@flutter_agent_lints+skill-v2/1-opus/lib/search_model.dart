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

  /// Bumped by every accepted query change, so a fetch started for an older
  /// query can tell that its result is no longer wanted.
  var _generation = 0;
  var _status = SearchStatus.idle;
  var _query = '';
  var _results = const <String>[];
  Object? _error;
  Timer? _timer;
  var _disposed = false;

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
    _generation++;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
    } else {
      final generation = _generation;
      _timer = Timer(_debounce, () => _startFetch(text, generation));
    }
    notifyListeners();
  }

  /// Re-runs the fetch for the current query immediately, skipping the
  /// debounce. Does nothing unless the last fetch ended in an error.
  void retry() {
    if (_disposed || _status != SearchStatus.error) {
      return;
    }
    // A debounced fetch may already be pending for a query typed after the
    // failure; this one replaces it.
    _timer?.cancel();
    _startFetch(_query, _generation);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _startFetch(String text, int generation) {
    if (_disposed || generation != _generation) {
      return;
    }
    _timer = null;
    _status = SearchStatus.loading;
    notifyListeners();
    unawaited(_fetch(text, generation));
  }

  Future<void> _fetch(String text, int generation) async {
    try {
      final fetched = await _fetcher(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _results = List.unmodifiable(fetched);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_disposed || generation != _generation) {
        return;
      }
      _results = const [];
      _error = error;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }
}
