import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The lifecycle of the search for the current query.
enum SearchStatus { idle, loading, success, error }

/// Debounced search over a [SearchFetcher], exposed as a [ChangeNotifier].
class SearchModel extends ChangeNotifier {
  factory SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) => SearchModel._(fetcher, debounce);

  SearchModel._(this._fetcher, this._debounce);

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;
  bool _disposed = false;

  /// Identifies the newest fetch; responses carrying an older id are stale.
  int _requestId = 0;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => List<String>.unmodifiable(_results);

  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_disposed || text == _query) return;

    _query = text;
    _timer?.cancel();
    _timer = null;
    // Any response still in flight belongs to an older query now.
    _requestId++;

    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    _timer = Timer(_debounce, () {
      _timer = null;
      _start(text);
    });
  }

  Future<void> _start(String text) async {
    if (_disposed) return;

    final id = ++_requestId;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _fetcher(text);
      if (_disposed || id != _requestId) return;
      _status = SearchStatus.success;
      _results = List<String>.of(fetched);
      _error = null;
    } catch (e) {
      if (_disposed || id != _requestId) return;
      _status = SearchStatus.error;
      _results = const <String>[];
      _error = e;
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
}
