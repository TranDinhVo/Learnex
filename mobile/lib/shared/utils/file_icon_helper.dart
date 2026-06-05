import 'package:flutter/material.dart';

class FileIconHelper {
  static IconData getIcon(String? fileUrl) {
    if (fileUrl == null) return Icons.insert_drive_file;
    final lowerUrl = fileUrl.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx')) {
      return Icons.description;
    } else if (lowerUrl.endsWith('.ppt') || lowerUrl.endsWith('.pptx')) {
      return Icons.slideshow;
    } else if (lowerUrl.endsWith('.xls') || lowerUrl.endsWith('.xlsx')) {
      return Icons.table_chart;
    }
    return Icons.insert_drive_file;
  }

  static Color getColor(String? fileUrl) {
    if (fileUrl == null) return Colors.grey.shade600;
    final lowerUrl = fileUrl.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      return Colors.red.shade600;
    } else if (lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx')) {
      return Colors.blue.shade600;
    } else if (lowerUrl.endsWith('.ppt') || lowerUrl.endsWith('.pptx')) {
      return Colors.orange.shade600;
    } else if (lowerUrl.endsWith('.xls') || lowerUrl.endsWith('.xlsx')) {
      return Colors.green.shade600;
    }
    return Colors.grey.shade600;
  }

  static Color getBackgroundColor(String? fileUrl) {
    if (fileUrl == null) return Colors.grey.shade100;
    final lowerUrl = fileUrl.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      return Colors.red.shade50;
    } else if (lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx')) {
      return Colors.blue.shade50;
    } else if (lowerUrl.endsWith('.ppt') || lowerUrl.endsWith('.pptx')) {
      return Colors.orange.shade50;
    } else if (lowerUrl.endsWith('.xls') || lowerUrl.endsWith('.xlsx')) {
      return Colors.green.shade50;
    }
    return Colors.grey.shade100;
  }
}
