import 'package:flutter/material.dart';

enum DocumentType {
  pdf,
  presentation,
  doc,
  zip,
}

class FolderDocument {
  const FolderDocument({
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
  });

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
}
