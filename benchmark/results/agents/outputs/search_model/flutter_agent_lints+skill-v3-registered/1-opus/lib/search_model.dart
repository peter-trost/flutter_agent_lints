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

  /// Bumped whenever the query changes, so a response that belongs to an
  /// earlier query can be recognised and dropped.
  var _generation = 0;
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
    _generation++;
    _timer?.cancel();
    _timer = null;

    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
      notifyListeners();
      return;
    }

    final generation = _generation;
    _timer = Timer(_debounce, () => unawaited(_fetch(text, generation)));
    notifyListeners();
  }

  Future<void> _fetch(String text, int generation) async {
    if (_isStale(generation)) {
      return;
    }
    _timer = null;
    _status = SearchStatus.loading;
    notifyListeners();

    try {
      final values = await _fetcher(text);
      if (_isStale(generation)) {
        return;
      }
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(values);
      _error = null;
    } on Object catch (e) {
      if (_isStale(generation)) {
        return;
      }
      _status = SearchStatus.error;
      _results = const [];
      _error = e;
    }
    notifyListeners();
  }

  bool _isStale(int generation) => _disposed || generation != _generation;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
