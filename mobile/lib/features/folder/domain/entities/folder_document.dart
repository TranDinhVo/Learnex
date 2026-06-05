import 'package:flutter/material.dart';

enum DocumentType {
  pdf,
  presentation,
  doc,
  zip,
}

class FolderDocument {
  final String title;
  final String fileName;
  final String category;
  final DocumentType type;
  final String author;
  final String downloads;
  final String fileSize;
  final int currentPage;
  final int totalPages;
  final String chapterTitle;
  final String summary;
  final Color accent;
  final Color iconColor;
  final bool isMine;
  final bool isSaved;

  /// Thêm property id để xử lý api
  final String id;
  final String fileUrl;

  const FolderDocument({
    this.id = '',
    required this.title,
    required this.fileName,
    required this.category,
    required this.type,
    required this.author,
    required this.downloads,
    required this.fileSize,
    required this.currentPage,
    required this.totalPages,
    required this.chapterTitle,
    required this.summary,
    required this.accent,
    required this.iconColor,
    required this.isMine,
    required this.isSaved,
    this.fileUrl = '',
  });

  factory FolderDocument.fromJson(Map<String, dynamic> json) {
    DocumentType docType = DocumentType.pdf;
    final fileType = json['file_type'] as String? ?? '';
    if (fileType.contains('presentation') || fileType.contains('powerpoint')) docType = DocumentType.presentation;
    else if (fileType.contains('word') || fileType.contains('document')) docType = DocumentType.doc;
    else if (fileType.contains('zip') || fileType.contains('archive')) docType = DocumentType.zip;

    // Convert file size from bytes
    final sizeBytes = json['file_size'] as int? ?? 0;
    String sizeStr;
    if (sizeBytes > 1024 * 1024) {
      sizeStr = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      sizeStr = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }

    // Default colors based on type
    Color accentColor = const Color(0xFFFEE2E2);
    Color iconColor = const Color(0xFFEF4444);
    switch (docType) {
      case DocumentType.presentation:
        accentColor = const Color(0xFFFFEDD5);
        iconColor = const Color(0xFFF97316);
        break;
      case DocumentType.doc:
        accentColor = const Color(0xFFDBEAFE);
        iconColor = const Color(0xFF3B82F6);
        break;
      case DocumentType.zip:
        accentColor = const Color(0xFFE9D5FF);
        iconColor = const Color(0xFF8B5CF6);
        break;
      case DocumentType.pdf:
      default:
        break;
    }

    return FolderDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fileName: 'Tài liệu',
      category: json['subject'] as String? ?? 'Chung',
      type: docType,
      author: json['author_name'] as String? ?? json['author_username'] as String? ?? 'Unknown',
      downloads: (json['download_count'] ?? 0).toString(),
      fileSize: sizeStr,
      currentPage: 1,
      totalPages: 1,
      chapterTitle: '',
      summary: json['description'] as String? ?? '',
      accent: accentColor,
      iconColor: iconColor,
      isMine: false, // Will be overridden if needed or we can ignore
      isSaved: json['is_saved'] as bool? ?? false,
      fileUrl: json['file_url'] as String? ?? '',
    );
  }
}
