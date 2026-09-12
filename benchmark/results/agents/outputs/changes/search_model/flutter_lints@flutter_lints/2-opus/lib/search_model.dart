import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search.
enum SearchStatus { idle, loading, success, error }

/// Debounces query changes and keeps the results of the latest search.
class SearchModel extends ChangeNotifier {
  SearchModel({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;
  bool _disposed = false;

  /// Identifies the latest started fetch; responses of any other are stale.
  int _requestId = 0;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  SearchStatus get status => _status;

  /// The latest text passed to [onQueryChanged].
  String get query => _query;

  List<String> get results => _results;

  /// The error of the latest failed fetch, or `null`.
  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _timer?.cancel();
    _timer = null;

    if (text.isEmpty) {
      // Drop whatever is in flight for an earlier query.
      _requestId++;
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    _timer = Timer(_debounce, () {
      _timer = null;
      _startFetch(_query);
    });
    notifyListeners();
  }

  /// Re-runs the fetch for [query] at once, skipping the debounce.
  ///
  /// Does nothing unless [status] is [SearchStatus.error].
  void retry() {
    if (_disposed || _status != SearchStatus.error) {
      return;
    }
    // A pending debounce would only fetch the same query again.
    _timer?.cancel();
    _timer = null;
    _startFetch(_query);
  }

  Future<void> _startFetch(String text) async {
    if (_disposed) {
      return;
    }
    final id = ++_requestId;
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();

    List<String> fetched;
    try {
      fetched = await _fetcher(text);
    } catch (error) {
      if (_isStale(id, text)) {
        return;
      }
      _status = SearchStatus.error;
      _error = error;
      _results = const <String>[];
      notifyListeners();
      return;
    }

    if (_isStale(id, text)) {
      return;
    }
    _status = SearchStatus.success;
    _error = null;
    _results = List<String>.unmodifiable(fetched);
    notifyListeners();
  }

  /// Whether the response of the fetch [id] for [text] may still be applied.
  ///
  /// A later fetch, or a query change that has not started its fetch yet,
  /// makes an earlier response stale.
  bool _isStale(int id, String text) =>
      _disposed || id != _requestId || text != _query;

  @override
  void notifyListeners() {
    if (_disposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
