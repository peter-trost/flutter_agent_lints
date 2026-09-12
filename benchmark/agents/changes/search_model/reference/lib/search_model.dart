import 'dart:async';

import 'package:flutter/foundation.dart';

typedef SearchFetcher = Future<List<String>> Function(String query);

enum SearchStatus { idle, loading, success, error }

class SearchModel extends ChangeNotifier {
  SearchModel({
    required this._fetcher,
    this._debounce = const Duration(milliseconds: 300),
  });

  final SearchFetcher _fetcher;
  final Duration _debounce;

  SearchStatus _status = SearchStatus.idle;
  String _query = '';
  List<String> _results = const [];
  Object? _error;
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;

  SearchStatus get status => _status;
  String get query => _query;
  List<String> get results => List.unmodifiable(_results);
  Object? get error => _error;

  void onQueryChanged(String text) {
    if (_disposed || text == _query) {
      return;
    }
    _query = text;
    _timer?.cancel();
    _generation++;
    if (text.isEmpty) {
      _status = SearchStatus.idle;
      _results = const [];
      _error = null;
      notifyListeners();
      return;
    }
    notifyListeners();
    _timer = Timer(_debounce, () => _fetch(text, _generation));
  }

  void retry() {
    if (_disposed || _status != SearchStatus.error) {
      return;
    }
    _timer?.cancel();
    _generation++;
    _fetch(_query, _generation);
  }

  void _fetch(String text, int generation) {
    if (_disposed) {
      return;
    }
    _status = SearchStatus.loading;
    notifyListeners();
    unawaited(_run(text, generation));
  }

  Future<void> _run(String text, int generation) async {
    try {
      final results = await _fetcher(text);
      if (_disposed || generation != _generation) {
        return;
      }
      _status = SearchStatus.success;
      _results = List.unmodifiable(results);
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

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
