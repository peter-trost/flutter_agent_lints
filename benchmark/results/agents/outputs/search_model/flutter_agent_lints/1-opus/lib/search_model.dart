import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search a [SearchModel] knows about.
enum SearchStatus { idle, loading, success, error }

/// Debounced search state: the newest query wins, stale answers are dropped.
class SearchModel extends ChangeNotifier {
  /// Searches with [fetcher] once [debounce] passed without a new query.
  new({required SearchFetcher fetcher, Duration debounce = _defaultDebounce})
    : _search = fetcher,
      _debounceDelay = debounce;

  static const _defaultDebounce = Duration(milliseconds: 300);

  final SearchFetcher _search;
  final Duration _debounceDelay;

  Timer? _timer;
  var _query = '';
  var _status = SearchStatus.idle;
  var _results = const <String>[];
  Object? _error;

  /// Identifies the current query; an answer to an older one is stale.
  var _generation = 0;
  var _disposed = false;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  /// Records [text] and schedules a fetch for it once the debounce elapses.
  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _error = null;
    _timer?.cancel();
    _generation++;
    if (text.isEmpty) {
      _timer = null;
      _status = SearchStatus.idle;
      _results = const [];
    } else {
      _status = SearchStatus.loading;
      final generation = _generation;
      _timer = Timer(_debounceDelay, () => unawaited(_fetch(text, generation)));
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
    if (_disposed) {
      return;
    }
    try {
      final items = await _search(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(items);
      _error = null;
    } on Object catch (e) {
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.error;
      _results = const [];
      _error = e;
    }
    notifyListeners();
  }
}
