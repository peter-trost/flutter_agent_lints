import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SearchFetcher = Future<List<String>> Function(String query);

enum SearchStatus { idle, loading, success, error }

class SearchModel extends ChangeNotifier {
  new({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  static const _empty = <String>[];

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;

  /// Identifies the fetch that owns the model's state. Every query change
  /// bumps it, so a response carrying an older value is stale.
  var _generation = 0;
  var _query = '';
  var _status = SearchStatus.idle;
  List<String> _results = _empty;
  Object? _error;
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
      _results = _empty;
      _error = null;
    } else {
      final generation = _generation;
      _timer = Timer(_debounce, () => unawaited(_fetch(text, generation)));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _generation++;
    super.dispose();
  }

  Future<void> _fetch(String text, int generation) async {
    if (_disposed || generation != _generation) {
      return;
    }
    _timer = null;
    _status = SearchStatus.loading;
    notifyListeners();
    try {
      final values = await _fetcher(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _results = List<String>.unmodifiable(values);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (e) {
      if (_disposed || generation != _generation) {
        return;
      }
      _results = _empty;
      _error = e;
      _status = SearchStatus.error;
    }
    notifyListeners();
  }
}
