import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the most recent search.
enum SearchStatus { idle, loading, success, error }

/// Runs a [SearchFetcher] over the typed query, debounced, and exposes the
/// state of the search to listeners.
///
/// Only the fetch for the query that is still current can change the state:
/// responses that arrive for an outdated query are dropped, whatever the
/// order in which the fetches complete.
class SearchModel extends ChangeNotifier {
  /// Creates a model that searches with [fetcher] once [debounce] has passed
  /// without a further change.
  SearchModel({
    required SearchFetcher fetcher,
    Duration debounce = const Duration(milliseconds: 300),
  }) : this._(fetcher, debounce);

  SearchModel._(this._fetcher, this._debounce);

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;

  /// Identifies the fetch whose result is still wanted. Bumping it drops
  /// whatever is in flight.
  int _requestId = 0;

  bool _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  /// The state of the latest search.
  SearchStatus get status => _status;

  /// The latest text passed to [onQueryChanged].
  String get query => _query;

  /// The results of the latest successful fetch, unmodifiable.
  List<String> get results => _results;

  /// The error of the latest failed fetch, or `null`.
  Object? get error => _error;

  /// Records [text] as the current query and schedules a fetch for it.
  ///
  /// Text equal to the current query changes nothing; an empty query resets
  /// the model to [SearchStatus.idle] without fetching.
  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _timer?.cancel();
    _timer = null;

    if (text.isEmpty) {
      _requestId++;
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    _timer = Timer(_debounce, () {
      _timer = null;
      unawaited(_fetch(text));
    });
  }

  Future<void> _fetch(String text) async {
    if (_disposed) {
      return;
    }
    final int id = ++_requestId;
    _status = SearchStatus.loading;
    notifyListeners();

    try {
      final List<String> fetched = await _fetcher(text);
      if (_disposed || id != _requestId) {
        return;
      }
      _results = List<String>.unmodifiable(fetched);
      _error = null;
      _status = SearchStatus.success;
    } on Object catch (error) {
      if (_disposed || id != _requestId) {
        return;
      }
      _error = error;
      _results = const <String>[];
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
