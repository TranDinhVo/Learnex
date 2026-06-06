import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';
import 'package:rxdart/rxdart.dart';

EventTransformer<T> debounce<T>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;
  static const int _limit = 20;

  String _currentQuery = '';
  String _currentType = 'all';

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(const Duration(milliseconds: 500)),
    );
    on<SearchTypeChanged>(_onTypeChanged);
    on<SearchLoadMore>(_onLoadMore);
  }

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      _currentQuery = '';
      emit(SearchInitial());
      return;
    }

    _currentQuery = query;
    emit(SearchLoading(query: _currentQuery, type: _currentType));

    try {
      final results = await repository.search(_currentQuery, _currentType, 1, _limit);
      final total = results['total'] as int? ?? 0;
      final currentItemCount = _countItems(results);
      final hasReachedMax = currentItemCount >= total || currentItemCount < _limit;

      emit(SearchLoaded(
        results: results,
        hasReachedMax: hasReachedMax,
        query: _currentQuery,
        type: _currentType,
        page: 1,
      ));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onTypeChanged(SearchTypeChanged event, Emitter<SearchState> emit) async {
    _currentType = event.type;
    if (_currentQuery.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading(query: _currentQuery, type: _currentType));
    try {
      final results = await repository.search(_currentQuery, _currentType, 1, _limit);
      final total = results['total'] as int? ?? 0;
      final currentItemCount = _countItems(results);
      final hasReachedMax = currentItemCount >= total || currentItemCount < _limit;

      emit(SearchLoaded(
        results: results,
        hasReachedMax: hasReachedMax,
        query: _currentQuery,
        type: _currentType,
        page: 1,
      ));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onLoadMore(SearchLoadMore event, Emitter<SearchState> emit) async {
    if (state is! SearchLoaded) return;
    final currentState = state as SearchLoaded;
    if (currentState.hasReachedMax) return;

    try {
      final nextPage = currentState.page + 1;
      final newResults = await repository.search(currentState.query, currentState.type, nextPage, _limit);
      
      final mergedResults = _mergeResults(currentState.results, newResults);
      final total = newResults['total'] as int? ?? 0;
      final currentItemCount = _countItems(mergedResults);
      final hasReachedMax = currentItemCount >= total || _countItems(newResults) == 0;

      emit(currentState.copyWith(
        results: mergedResults,
        hasReachedMax: hasReachedMax,
        page: nextPage,
      ));
    } catch (e) {
      // Bỏ qua lỗi load more, giữ nguyên state cũ
    }
  }

  int _countItems(Map<String, dynamic> results) {
    int count = 0;
    if (results['users'] != null) count += (results['users'] as List).length;
    if (results['posts'] != null) count += (results['posts'] as List).length;
    if (results['documents'] != null) count += (results['documents'] as List).length;
    return count;
  }

  Map<String, dynamic> _mergeResults(Map<String, dynamic> oldRes, Map<String, dynamic> newRes) {
    final merged = <String, dynamic>{
      'total': newRes['total'] ?? oldRes['total'],
    };

    if (oldRes['users'] != null || newRes['users'] != null) {
      merged['users'] = [
        ...?(oldRes['users'] as List?),
        ...?(newRes['users'] as List?)
      ];
    }
    if (oldRes['posts'] != null || newRes['posts'] != null) {
      merged['posts'] = [
        ...?(oldRes['posts'] as List?),
        ...?(newRes['posts'] as List?)
      ];
    }
    if (oldRes['documents'] != null || newRes['documents'] != null) {
      merged['documents'] = [
        ...?(oldRes['documents'] as List?),
        ...?(newRes['documents'] as List?)
      ];
    }

    return merged;
  }
}
