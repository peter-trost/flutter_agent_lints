import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search.
enum SearchStatus { idle, loading, success, error }

/// Debounced search over a [SearchFetcher].
///
/// Only the newest query matters: a response that arrives for a query that is
/// no longer current is dropped, whatever the order the fetches complete in.
class SearchModel extends ChangeNotifier {
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) : this._(fetcher, debounce);

  // The fields are private, so they cannot be named initializing formals.
  SearchModel._(this._fetcher, this._debounce);

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;

  /// Identifies the fetch whose result is still wanted. Bumping it drops any
  /// response still in flight.
  int _generation = 0;
  bool _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  SearchStatus get status => _status;

  /// The latest text passed to [onQueryChanged].
  String get query => _query;

  /// The results of the latest successful fetch, unmodifiable.
  List<String> get results => _results;

  /// The error of the latest failed fetch, or null.
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
      _results = const <String>[];
      _error = null;
    } else {
      _timer = Timer(_debounce, () => _start(text));
    }
    notifyListeners();
  }

  void _start(String text) {
    if (_disposed) {
      return;
    }
    _timer = null;
    _status = SearchStatus.loading;
    notifyListeners();
    unawaited(_fetch(++_generation, text));
  }

  Future<void> _fetch(int generation, String text) async {
    try {
      final List<String> values = await _fetcher(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _results = List<String>.unmodifiable(values);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_disposed || generation != _generation) {
        return;
      }
      _results = const <String>[];
      _error = error;
      _status = SearchStatus.error;
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
}
