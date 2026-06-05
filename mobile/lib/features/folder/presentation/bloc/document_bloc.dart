import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/document_repository_impl.dart';
import 'document_event.dart';
import 'document_state.dart';

/// BLoC quản lý tài liệu: tải, tìm kiếm, upload, download, xoá.
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepositoryImpl _repository;

  DocumentBloc({required DocumentRepositoryImpl repository})
      : _repository = repository,
        super(DocumentInitial()) {
    on<LoadDocumentsEvent>(_onLoad);
    on<LoadMoreDocumentsEvent>(_onLoadMore);
    on<SearchDocumentsEvent>(_onSearch);
    on<LoadRecommendationsEvent>(_onRecommendations);
    on<UploadDocumentEvent>(_onUpload);
    on<DownloadDocumentEvent>(_onDownload);
    on<DeleteDocumentEvent>(_onDelete);
    on<LoadMyDocumentsEvent>(_onLoadMyDocuments);
    on<LoadSavedDocumentsEvent>(_onLoadSavedDocuments);
    on<ToggleSaveDocumentEvent>(_onToggleSave);
    on<LoadSubjectsEvent>(_onLoadSubjects);
  }

  Future<void> _onLoad(LoadDocumentsEvent event, Emitter<DocumentState> emit) async {
    emit(DocumentLoading());
    try {
      final result = await _repository.getAll(page: 1, subject: event.subject);
      final docs = _extractList(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = 1 < (pagination?['totalPages'] ?? 1);
      emit(DocumentsLoaded(documents: docs, hasMore: hasMore, currentPage: 1));
    } on DioException catch (e) {
      emit(DocumentError(_extractError(e)));
    } catch (e) {
      emit(DocumentError('Không thể tải tài liệu.'));
    }
  }

  Future<void> _onLoadMore(LoadMoreDocumentsEvent event, Emitter<DocumentState> emit) async {
    final currentState = state;
    if (currentState is! DocumentsLoaded || !currentState.hasMore) return;
    final nextPage = currentState.currentPage + 1;
    try {
      final result = await _repository.getAll(page: nextPage);
      final newDocs = _extractList(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = nextPage < (pagination?['totalPages'] ?? 1);
      emit(DocumentsLoaded(
        documents: [...currentState.documents, ...newDocs],
        hasMore: hasMore,
        currentPage: nextPage,
      ));
    } catch (_) {
      emit(currentState);
    }
  }

  Future<void> _onSearch(SearchDocumentsEvent event, Emitter<DocumentState> emit) async {
    emit(DocumentLoading());
    try {
      final result = await _repository.search(event.query);
      final docs = _extractList(result);
      emit(DocumentSearchResults(docs));
    } catch (e) {
      emit(DocumentError('Tìm kiếm thất bại.'));
    }
  }

  Future<void> _onRecommendations(LoadRecommendationsEvent event, Emitter<DocumentState> emit) async {
    try {
      final result = await _repository.getRecommendations();
      final docs = _extractList(result);
      emit(DocumentRecommendationsLoaded(docs));
    } catch (_) {}
  }

  Future<void> _onUpload(UploadDocumentEvent event, Emitter<DocumentState> emit) async {
    emit(DocumentUploading());
    try {
      final result = await _repository.upload(
        filePath: event.filePath,
        fileBytes: event.fileBytes,
        fileName: event.fileName,
        title: event.title,
        description: event.description,
        subject: event.subject,
        tags: event.tags,
      );
      final data = result['data'] ?? result;
      emit(DocumentUploaded(data as Map<String, dynamic>));
      // Load user's own docs so they see their new upload immediately (even if pending approval)
      add(LoadMyDocumentsEvent());
    } on DioException catch (e) {
      emit(DocumentUploadError(_extractError(e)));
    } catch (e) {
      emit(DocumentUploadError('Upload tài liệu thất bại.'));
    }
  }

  Future<void> _onDownload(DownloadDocumentEvent event, Emitter<DocumentState> emit) async {
    try {
      final url = await _repository.download(event.documentId);
      emit(DocumentDownloadReady(url));
    } catch (_) {}
  }

  Future<void> _onDelete(DeleteDocumentEvent event, Emitter<DocumentState> emit) async {
    final currentState = state;
    try {
      await _repository.delete(event.documentId);
      if (currentState is DocumentsLoaded) {
        final updatedDocs = currentState.documents
            .where((doc) => doc['id'].toString() != event.documentId)
            .toList();
        emit(DocumentsLoaded(
          documents: updatedDocs,
          hasMore: currentState.hasMore,
          currentPage: currentState.currentPage,
        ));
      } else {
        add(LoadDocumentsEvent());
      }
    } catch (_) {}
  }

  Future<void> _onLoadMyDocuments(LoadMyDocumentsEvent event, Emitter<DocumentState> emit) async {
    emit(DocumentLoading());
    try {
      final result = await _repository.getMine(page: 1, subject: event.subject);
      final docs = _extractList(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = 1 < (pagination?['totalPages'] ?? 1);
      emit(DocumentsLoaded(documents: docs, hasMore: hasMore, currentPage: 1));
    } on DioException catch (e) {
      emit(DocumentError(_extractError(e)));
    } catch (e) {
      emit(DocumentError('Không thể tải tài liệu của tôi.'));
    }
  }

  Future<void> _onLoadSavedDocuments(LoadSavedDocumentsEvent event, Emitter<DocumentState> emit) async {
    emit(DocumentLoading());
    try {
      final result = await _repository.getSaved(page: 1, subject: event.subject);
      final docs = _extractList(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = 1 < (pagination?['totalPages'] ?? 1);
      emit(DocumentsLoaded(documents: docs, hasMore: hasMore, currentPage: 1));
    } on DioException catch (e) {
      emit(DocumentError(_extractError(e)));
    } catch (e) {
      emit(DocumentError('Không thể tải tài liệu đã lưu.'));
    }
  }

  Future<void> _onToggleSave(ToggleSaveDocumentEvent event, Emitter<DocumentState> emit) async {
    try {
      final result = await _repository.toggleSave(event.documentId);
      emit(DocumentSaveToggled(
        documentId: event.documentId,
        isSaved: result['data']?['is_saved'] ?? result['is_saved'] ?? false,
      ));
    } catch (_) {}
  }

  Future<void> _onLoadSubjects(LoadSubjectsEvent event, Emitter<DocumentState> emit) async {
    try {
      final subjects = await _repository.getSubjects();
      emit(SubjectsLoaded(subjects));
    } catch (_) {}
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data['message'] as String? ?? 'Lỗi';
    } catch (_) {}
    return e.message ?? 'Đã có lỗi xảy ra';
  }
}
