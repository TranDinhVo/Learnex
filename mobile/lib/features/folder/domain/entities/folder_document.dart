import 'package:flutter/material.dart';
import '../../../../shared/utils/file_icon_helper.dart';

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
  final String userId;
  final String approvalStatus; // 'pending' | 'approved' | 'rejected'

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
    this.userId = '',
    this.approvalStatus = 'pending',
  });

  factory FolderDocument.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    DocumentType docType = DocumentType.pdf;
    final fileType = json['file_type'] as String? ?? '';
    if (fileType.contains('presentation') || fileType.contains('powerpoint')) docType = DocumentType.presentation;
    else if (fileType.contains('word') || fileType.contains('document')) docType = DocumentType.doc;
    else if (fileType.contains('zip') || fileType.contains('archive')) docType = DocumentType.zip;

    // Convert file size from bytes
    final rawSize = json['file_size'];
    final sizeBytes = rawSize is num ? rawSize.toInt() : (rawSize is String ? int.tryParse(rawSize) ?? 0 : 0);
    String sizeStr;
    if (sizeBytes > 1024 * 1024) {
      sizeStr = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      sizeStr = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }

    final fileUrl = json['file_url'] as String? ?? '';
    Color accentColor = FileIconHelper.getBackgroundColor(fileUrl);
    Color iconColor = FileIconHelper.getColor(fileUrl);

    final docUserId = json['user_id'] as String? ?? '';
    final isMine = currentUserId != null && docUserId == currentUserId;

    return FolderDocument(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      fileName: json['title'] as String? ?? 'Tài liệu',
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
      isMine: json['is_mine'] as bool? ?? isMine,
      isSaved: json['is_saved'] as bool? ?? false,
      fileUrl: json['file_url'] as String? ?? '',
      userId: docUserId,
      approvalStatus: json['approval_status'] as String? ?? 'pending',
    );
  }
}
