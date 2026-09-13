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
  var _results = const <String>[];
  Object? _error;
  var _generation = 0;
  var _disposed = false;

  SearchStatus get status => _status;

  String get query => _query;

  List<String> get results => _results;

  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    // Every change invalidates whatever is still in flight, so a response
    // that arrives late can no longer overwrite a newer one.
    _generation++;
    _timer?.cancel();
    _timer = null;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const <String>[];
      _error = null;
    } else {
      _timer = Timer(_debounce, _startFetch);
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

  void _startFetch() {
    _timer = null;
    if (_disposed) {
      return;
    }
    _status = SearchStatus.loading;
    notifyListeners();
    _fetch(_generation, _query).ignore();
  }

  Future<void> _fetch(int generation, String query) async {
    List<String>? fetched;
    Object? failure;
    try {
      fetched = await _fetcher(query);
    } on Object catch (thrown) {
      failure = thrown;
    }
    if (_disposed || generation != _generation) {
      return;
    }
    if (fetched == null) {
      _status = SearchStatus.error;
      _results = const <String>[];
      _error = failure;
    } else {
      _status = SearchStatus.success;
      _results = List<String>.unmodifiable(fetched);
      _error = null;
    }
    notifyListeners();
  }
}
