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

  var _status = SearchStatus.idle;
  var _query = '';
  var _results = <String>[];
  Object? _error;

  /// Identifies the query a fetch belongs to. Every change to the query, and
  /// disposal, moves it on, so an older response can tell it is stale.
  var _generation = 0;
  var _disposed = false;
  Timer? _timer;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => UnmodifiableListView(_results);

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
      _results = <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    final generation = _generation;
    _timer = Timer(_debounce, () => unawaited(_fetch(text, generation)));
    notifyListeners();
  }

  Future<void> _fetch(String text, int generation) async {
    if (_disposed || generation != _generation) {
      return;
    }
    _status = SearchStatus.loading;
    notifyListeners();

    try {
      final values = await _fetcher(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _results = List<String>.of(values);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (e) {
      if (_disposed || generation != _generation) {
        return;
      }
      _results = <String>[];
      _error = e;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
