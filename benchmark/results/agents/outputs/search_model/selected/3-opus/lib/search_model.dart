import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search a [SearchModel] cares about.
enum SearchStatus { idle, loading, success, error }

/// Debounced search state: the newest query always wins, and results that
/// belong to an older query are discarded whenever they arrive.
class SearchModel extends ChangeNotifier {
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) : this._(fetcher, debounce);

  SearchModel._(this._fetcher, this._debounce);

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;

  /// Identifies the fetch whose result is still wanted. Bumping it makes every
  /// fetch started earlier stale.
  int _generation = 0;
  bool _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = List<String>.unmodifiable(const <String>[]);
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
    // Anything already in flight belongs to an older query now.
    _generation++;

    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = List<String>.unmodifiable(const <String>[]);
      _error = null;
    } else {
      _timer = Timer(_debounce, () => unawaited(_fetch(text)));
    }
    notifyListeners();
  }

  Future<void> _fetch(String text) async {
    if (_disposed) {
      return;
    }
    _timer = null;
    final int generation = ++_generation;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();

    List<String> data;
    try {
      data = await _fetcher(text);
    } on Object catch (error) {
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.error;
      _results = List<String>.unmodifiable(const <String>[]);
      _error = error;
      notifyListeners();
      return;
    }

    if (_disposed || generation != _generation) {
      return;
    }
    _status = SearchStatus.success;
    _results = List<String>.unmodifiable(data);
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    // Drop whatever is still in flight.
    _generation++;
    super.dispose();
  }
}
