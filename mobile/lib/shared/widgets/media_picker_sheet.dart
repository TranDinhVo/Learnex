import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart'; // XFile
import 'package:file_picker/file_picker.dart';

/// Bottom sheet dùng chung để chọn ảnh (Camera/Gallery) hoặc file đính kèm.
///
/// Sử dụng [XFile] thay vì dart:io [File] → hoạt động trên cả Web lẫn Mobile.
class MediaPickerSheet extends StatelessWidget {
  final Function(XFile file) onImagePicked;
  final Function(XFile file) onFilePicked;

  const MediaPickerSheet({
    super.key,
    required this.onImagePicked,
    required this.onFilePicked,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (xFile != null) {
        onImagePicked(xFile);
      }
    } catch (_) {
      // Lỗi (nếu có) sẽ được xử lý bởi _uploadAndSend trong màn hình cha
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        // Web cần withData: true vì không có đường dẫn file
        // Mobile dùng withData: false để tiết kiệm RAM (đọc file khi upload)
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final platformFile = result.files.single;
      XFile xFile;

      if (!kIsWeb && platformFile.path != null) {
        // Mobile: dùng đường dẫn thực
        xFile = XFile(platformFile.path!, name: platformFile.name);
      } else if (platformFile.bytes != null) {
        // Web: dùng bytes (blob)
        xFile = XFile.fromData(
          platformFile.bytes!,
          name: platformFile.name,
          mimeType: platformFile.extension != null
              ? _getMimeType(platformFile.extension!)
              : null,
        );
      } else {
        return; // Không đọc được file
      }

      onFilePicked(xFile);
    } catch (_) {
      // Lỗi sẽ được xử lý bởi _uploadAndSend trong màn hình cha
    }
  }

  String? _getMimeType(String extension) {
    const map = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'zip': 'application/zip',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
    };
    return map[extension.toLowerCase()];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Camera — chỉ hiện trên Mobile (Web không có camera native)
          if (!kIsWeb)
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF4F46E5), size: 22),
              ),
              title: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Mở camera để chụp'),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
          // Gallery — hiện trên cả Web & Mobile
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_library, color: Colors.green, size: 22),
            ),
            title: const Text(
              kIsWeb ? 'Tải ảnh lên' : 'Thư viện ảnh',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(kIsWeb ? 'Chọn ảnh từ máy tính' : 'Chọn từ bộ sưu tập'),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          // File picker — hiện trên cả Web & Mobile
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file, color: Colors.orange, size: 22),
            ),
            title: const Text('Tệp đính kèm', style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('PDF, Word, Video... (tối đa 50MB)'),
            onTap: () => _pickFile(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
