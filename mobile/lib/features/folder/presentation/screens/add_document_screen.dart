import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/utils/file_icon_helper.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';

class AddDocumentScreen extends StatefulWidget {
  const AddDocumentScreen({super.key});

  static const routeName = '/add-document';

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  PlatformFile? _pickedFile;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<String> _tags = [];
  String? _subject;

  List<String> _subjects = [];

  final List<String> _availableTags = [
    'Giải tích',
    'Kỳ 2',
    'Đề cương',
    'Bài tập',
    'Ôn thi',
    'Tổng hợp',
    'Tham khảo',
  ];

  bool get _canUpload {
    return _pickedFile != null &&
        _titleCtrl.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(LoadSubjectsEvent());
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx'],
      withData: kIsWeb,
    );
    if (result == null) return;
    final file = result.files.first;
    const maxBytes = 25 * 1024 * 1024; // 25MB
    if (file.size > maxBytes) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tập tin vượt quá 25MB.')));
      }
      return;
    }
    setState(() => _pickedFile = file);
  }

  void _removeTag(String t) {
    setState(() => _tags.remove(t));
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  bool _isUploading = false;

  void _onUpload() {
    if (_pickedFile == null) return;
    final String? safePath = kIsWeb ? null : _pickedFile!.path;
    
    if (safePath == null && _pickedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: File không có đường dẫn hoặc dữ liệu byte.')),
      );
      return;
    }
    
    setState(() => _isUploading = true);

    context.read<DocumentBloc>().add(
      UploadDocumentEvent(
        filePath: safePath,
        fileBytes: _pickedFile!.bytes?.toList(),
        fileName: _pickedFile!.name,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        subject: _subject,
        tags: _tags,
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black45,
      body: BlocListener<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentUploaded) {
            setState(() => _isUploading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🎉 Tài liệu đã được tải lên thành công!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).maybePop(state.document);
          } else if (state is DocumentUploadError) {
            setState(() => _isUploading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.message}'), backgroundColor: Colors.red),
            );
          } else if (state is DocumentUploading) {
            setState(() => _isUploading = true);
          } else if (state is SubjectsLoaded) {
            setState(() {
              _subjects = state.subjects.map((e) => e['name'].toString()).toList();
            });
          }
        },
        child: SafeArea(
          child: Stack(
          children: [
            // Backdrop - taps outside close
            GestureDetector(onTap: () => Navigator.of(context).maybePop()),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Chia sẻ tài liệu',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: (_canUpload && !_isUploading) ? _onUpload : null,
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              child: _isUploading 
                                  ? const SizedBox(
                                      width: 20, height: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : const Text('Đăng'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // File zone
                              InkWell(
                                onTap: _pickFile,
                                child: Container(
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
                                      width: 1.6,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _pickedFile == null ? Icons.cloud_upload : FileIconHelper.getIcon(_pickedFile!.name),
                                            size: 32,
                                            color: _pickedFile == null ? Colors.blue : FileIconHelper.getColor(_pickedFile!.name),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (_pickedFile == null) ...[
                                          Text(
                                            'Nhấn để chọn tài liệu',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  color: theme.primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'PDF, DOCX, PPTX (Tối đa 25MB)',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                        ] else ...[
                                          Text(
                                            _pickedFile!.name,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${(_pickedFile!.size / 1024).toStringAsFixed(0)} KB',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Title
                              Text(
                                'Tiêu đề tài liệu *',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _titleCtrl,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  hintText:
                                      'Nhập tiêu đề ấn tượng cho tài liệu của bạn',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 14),
                              // Description
                              Text(
                                'Mô tả (tùy chọn)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _descCtrl,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  hintText:
                                      'Chia sẻ thêm về nội dung hoặc mục đích của tài liệu này...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Subject
                              Text(
                                'Môn học (tùy chọn)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _subject,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text('Chọn môn học liên quan'),
                                items: _subjects
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _subject = v),
                              ),
                              const SizedBox(height: 14),
                              // Tags
                              Text(
                                'Tags',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_tags.isNotEmpty) ...[
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final t in _tags)
                                            FilterChip(
                                              label: Text(t),
                                              selected: true,
                                              onSelected: (_) => _removeTag(t),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Text(
                                      'Chọn tag phù hợp',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final tag in _availableTags)
                                          FilterChip(
                                            label: Text(tag),
                                            selected: _tags.contains(tag),
                                            onSelected: (_) => _toggleTag(tag),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Helper
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade300,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Tài liệu của bạn sẽ được kiểm duyệt trước khi hiển thị công khai. Vui lòng đảm bảo không vi phạm bản quyền và quy tắc cộng đồng.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
