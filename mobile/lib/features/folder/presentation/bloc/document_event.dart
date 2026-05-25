/// Events cho DocumentBloc
abstract class DocumentEvent {}

class LoadDocumentsEvent extends DocumentEvent {
  final String? subject;
  LoadDocumentsEvent({this.subject});
}

class LoadMoreDocumentsEvent extends DocumentEvent {}

class SearchDocumentsEvent extends DocumentEvent {
  final String query;
  SearchDocumentsEvent({required this.query});
}

class LoadRecommendationsEvent extends DocumentEvent {}

class UploadDocumentEvent extends DocumentEvent {
  final String filePath;
  final String title;
  final String? description;
  final String? subject;
  final List<String>? tags;
  UploadDocumentEvent({
    required this.filePath,
    required this.title,
    this.description,
    this.subject,
    this.tags,
  });
}

class DownloadDocumentEvent extends DocumentEvent {
  final String documentId;
  DownloadDocumentEvent({required this.documentId});
}

class DeleteDocumentEvent extends DocumentEvent {
  final String documentId;
  DeleteDocumentEvent({required this.documentId});
}
