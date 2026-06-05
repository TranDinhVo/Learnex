/// States cho DocumentBloc
abstract class DocumentState {}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentsLoaded extends DocumentState {
  final List<Map<String, dynamic>> documents;
  final bool hasMore;
  final int currentPage;
  DocumentsLoaded({
    required this.documents,
    this.hasMore = true,
    this.currentPage = 1,
  });
}

class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}

class DocumentUploading extends DocumentState {}

class DocumentUploaded extends DocumentState {
  final Map<String, dynamic> document;
  DocumentUploaded(this.document);
}

class DocumentUploadError extends DocumentState {
  final String message;
  DocumentUploadError(this.message);
}

class DocumentDownloadReady extends DocumentState {
  final String downloadUrl;
  DocumentDownloadReady(this.downloadUrl);
}

class DocumentSearchResults extends DocumentState {
  final List<Map<String, dynamic>> results;
  DocumentSearchResults(this.results);
}

class DocumentRecommendationsLoaded extends DocumentState {
  final List<Map<String, dynamic>> recommendations;
  DocumentRecommendationsLoaded(this.recommendations);
}

class DocumentSaveToggled extends DocumentState {
  final String documentId;
  final bool isSaved;
  DocumentSaveToggled({required this.documentId, required this.isSaved});
}

class SubjectsLoaded extends DocumentState {
  final List<dynamic> subjects;
  SubjectsLoaded(this.subjects);
}
