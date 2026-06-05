/// Events cho DocumentBloc
abstract class DocumentEvent {}

class LoadDocumentsEvent extends DocumentEvent {
  final String? subject;
  LoadDocumentsEvent({this.subject});
}

class LoadMyDocumentsEvent extends DocumentEvent {
  final String? subject;
  LoadMyDocumentsEvent({this.subject});
}

class LoadSavedDocumentsEvent extends DocumentEvent {
  final String? subject;
  LoadSavedDocumentsEvent({this.subject});
}

class LoadMoreDocumentsEvent extends DocumentEvent {}

class LoadSubjectsEvent extends DocumentEvent {}

class SearchDocumentsEvent extends DocumentEvent {
  final String query;
  SearchDocumentsEvent({required this.query});
}

class LoadRecommendationsEvent extends DocumentEvent {}

class UploadDocumentEvent extends DocumentEvent {
  final String? filePath;
  final List<int>? fileBytes;
  final String fileName;
  final String title;
  final String? description;
  final String? subject;
  final List<String>? tags;
  UploadDocumentEvent({
    this.filePath,
    this.fileBytes,
    required this.fileName,
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

class ToggleSaveDocumentEvent extends DocumentEvent {
  final String documentId;
  ToggleSaveDocumentEvent({required this.documentId});
}
