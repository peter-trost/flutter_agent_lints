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
  List<String> _results = const [];
  Object? _error;

  /// Identifies the newest request. Every query change bumps it, so a fetch
  /// that started under an older value can no longer win.
  var _requestId = 0;

  var _isDisposed = false;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_isDisposed || text == _query) {
      return;
    }
    _query = text;
    _requestId++;
    _timer?.cancel();
    _timer = null;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
    } else {
      _timer = Timer(_debounce, _startFetch);
    }
    notifyListeners();
  }

  /// Re-runs the fetch for the current [query] straight away, skipping the
  /// debounce. Does nothing unless [status] is [SearchStatus.error].
  void retry() {
    if (_isDisposed || _status != SearchStatus.error) {
      return;
    }
    _requestId++;
    _timer?.cancel();
    _startFetch();
  }

  void _startFetch() {
    _timer = null;
    if (_isDisposed) {
      return;
    }
    _status = SearchStatus.loading;
    _error = null;
    notifyListeners();
    unawaited(_fetch(_requestId, _query));
  }

  Future<void> _fetch(int requestId, String text) async {
    final List<String> fetched;
    try {
      fetched = await _fetcher(text);
    } on Object catch (error) {
      if (_isDisposed || requestId != _requestId) {
        return;
      }
      _status = SearchStatus.error;
      _error = error;
      _results = const [];
      notifyListeners();
      return;
    }
    if (_isDisposed || requestId != _requestId) {
      return;
    }
    _status = SearchStatus.success;
    _error = null;
    _results = List<String>.unmodifiable(fetched);
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
