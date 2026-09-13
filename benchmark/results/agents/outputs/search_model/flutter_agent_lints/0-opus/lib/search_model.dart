import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs the search for [query] and completes with the matching entries.
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the most recent search.
enum SearchStatus { idle, loading, success, error }

/// Debounces query changes and exposes the result of the latest search.
class SearchModel extends ChangeNotifier {
  new({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  /// Incremented on every accepted query change, so a response can tell
  /// whether the query it was started for is still the current one.
  var _generation = 0;
  Timer? _timer;
  var _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  var _query = '';
  List<String> _results = const [];
  Object? _error;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  /// Records [text] as the current query and schedules a fetch for it once
  /// [_debounce] has passed without a further change.
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
    } else {
      final generation = _generation;
      _timer = Timer(_debounce, () {
        unawaited(_fetch(text, generation));
      });
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

  Future<void> _fetch(String text, int generation) async {
    if (_disposed || generation != _generation) {
      return;
    }
    _timer = null;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final values = await _fetcher(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(values);
      _error = null;
    } on Object catch (error) {
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.error;
      _results = const [];
      _error = error;
    }
    notifyListeners();
  }
}
