import 'dart:async';

import 'package:flutter/foundation.dart';

/// Fetches the results for [query].
typedef SearchFetcher = Future<List<String>> Function(String query);

/// The state of the latest search.
enum SearchStatus { idle, loading, success, error }

/// Debounced search state holder.
///
/// Text changes are stored immediately, but a fetch only starts once the
/// debounce duration has elapsed without another change. Responses that no
/// longer match the current query are dropped, so stale results can never
/// overwrite newer ones.
class SearchModel extends ChangeNotifier {
  SearchModel({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  Timer? _timer;

  /// Incremented whenever the query changes or the model is disposed, so that
  /// in-flight fetches started for an older value can be identified and
  /// discarded.
  int _generation = 0;
  bool _disposed = false;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const <String>[];
  Object? _error;

  SearchStatus get status => _status;

  /// The latest text passed to [onQueryChanged].
  String get query => _query;

  /// The results of the latest successful fetch. Unmodifiable.
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
    _generation++;

    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    final generation = _generation;
    _timer = Timer(_debounce, () => _fetch(text, generation));
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
      _results = List<String>.unmodifiable(values);
      _status = SearchStatus.success;
      _error = null;
    } catch (error) {
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
    _generation++;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
