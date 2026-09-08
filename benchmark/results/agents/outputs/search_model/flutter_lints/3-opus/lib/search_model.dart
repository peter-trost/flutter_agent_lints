import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search.
enum SearchStatus { idle, loading, success, error }

/// Debounces query changes and exposes the state of the resulting search.
class SearchModel extends ChangeNotifier {
  /// Creates a model that calls [fetcher] once [debounce] has passed without
  /// another query change.
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    // Assigned in the body because named parameters cannot be private, so
    // these fields cannot be initializing formals.
    _fetcher = fetcher;
    _debounce = debounce;
  }

  late final SearchFetcher _fetcher;
  late final Duration _debounce;

  Timer? _timer;
  bool _disposed = false;

  /// Identifies the newest accepted query; responses stamped with an older id
  /// are stale and dropped.
  int _requestId = 0;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  /// The state of the latest search.
  SearchStatus get status => _status;

  /// The latest text passed to [onQueryChanged].
  String get query => _query;

  /// The results of the latest successful fetch.
  List<String> get results => UnmodifiableListView<String>(_results);

  /// The error of the latest failed fetch, or `null`.
  Object? get error => _error;

  /// Stores [text] and schedules a fetch for it.
  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }

    _timer?.cancel();
    _timer = null;
    _requestId++;
    _query = text;

    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    final int requestId = _requestId;
    _timer = Timer(_debounce, () {
      _timer = null;
      unawaited(_fetch(text, requestId));
    });
  }

  Future<void> _fetch(String text, int requestId) async {
    if (_disposed || requestId != _requestId) {
      return;
    }

    _status = SearchStatus.loading;
    notifyListeners();

    try {
      final List<String> fetched = await _fetcher(text);
      if (_disposed || requestId != _requestId) {
        return;
      }
      _results = List<String>.unmodifiable(fetched);
      _error = null;
      _status = SearchStatus.success;
    } catch (error) {
      if (_disposed || requestId != _requestId) {
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
    super.dispose();
  }
}
