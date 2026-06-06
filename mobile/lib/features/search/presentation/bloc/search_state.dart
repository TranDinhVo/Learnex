import 'package:equatable/equatable.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {
  final String query;
  final String type;
  
  const SearchLoading({required this.query, required this.type});
  
  @override
  List<Object?> get props => [query, type];
}

class SearchLoaded extends SearchState {
  final Map<String, dynamic> results;
  final bool hasReachedMax;
  final String query;
  final String type;
  final int page;

  const SearchLoaded({
    required this.results,
    required this.hasReachedMax,
    required this.query,
    required this.type,
    required this.page,
  });

  SearchLoaded copyWith({
    Map<String, dynamic>? results,
    bool? hasReachedMax,
    String? query,
    String? type,
    int? page,
  }) {
    return SearchLoaded(
      results: results ?? this.results,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      query: query ?? this.query,
      type: type ?? this.type,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [results, hasReachedMax, query, type, page];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
