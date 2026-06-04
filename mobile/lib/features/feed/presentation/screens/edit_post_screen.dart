import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/document_picker_bottom_sheet.dart';
import '../widgets/attached_document_card.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/enums/post_visibility.dart';
import '../widgets/post_visibility_bottom_sheet.dart';
import '../widgets/tag_user_bottom_sheet.dart';

import '../../../../shared/utils/image_parser.dart';

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;
  PostVisibility _selectedVisibility = PostVisibility.public;
  Map<String, dynamic>? _attachedDocument;
  List<Map<String, dynamic>> _taggedUsers = [];

  final List<dynamic> _currentImages = []; // Có thể là String (URL cũ) hoặc XFile (ảnh mới)

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post['content'] ?? '';
    
    // Visibility
    final vis = widget.post['visibility']?.toString() ?? 'public';
    _selectedVisibility = PostVisibility.values.firstWhere(
      (e) => e.value == vis,
      orElse: () => PostVisibility.public,
    );

    // Tagged users
    final tags = widget.post['tagged_users'];
    if (tags is List) {
      _taggedUsers = tags
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    // Document
    if (widget.post['document_id'] != null) {
      _attachedDocument = {
        'id': widget.post['document_id'],
        'title': widget.post['document_title'] ?? 'Tài liệu',
        'file_size': widget.post['document_size'],
        'file_url': widget.post['document_url'],
      };
    }

    // Images
    final parsedImages = ImageParser.parseImageUrls(widget.post['image_urls']);
    _currentImages.addAll(parsedImages);

    _contentController.addListener(() {
      setState(() {}); // Rebuild để cập nhật character count & button state
    });
  }

  bool get _canSubmit {
    final content = _contentController.text.trim();
    final hasContent = content.isNotEmpty || _currentImages.isNotEmpty || _attachedDocument != null;
    final isUnderLimit = content.length <= 2000;
    return hasContent && isUnderLimit && !_isSubmitting;
  }

  Future<void> _pickImages() async {
    if (_currentImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được có tối đa 5 ảnh')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (final xFile in pickedFiles) {
        if (_currentImages.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chỉ được có tối đa 5 ảnh')),
          );
          break;
        }
        
        final sizeBytes = await xFile.length();
        final sizeMB = sizeBytes / (1024 * 1024);
        if (sizeMB > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ảnh ${xFile.name} vượt quá 10MB và đã bị bỏ qua')),
          );
          continue;
        }
        
        setState(() {
          _currentImages.add(xFile);
        });
      }
    }
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty && _currentImages.isEmpty && _attachedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm nội dung, ảnh hoặc tài liệu trước khi đăng')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final newFiles = _currentImages.whereType<XFile>().toList();

    if (newFiles.isNotEmpty) {
      context.read<FeedBloc>().add(
        UploadImagesEvent(files: newFiles),
      );
    } else {
      final oldUrls = _currentImages.whereType<String>().toList();
      context.read<FeedBloc>().add(
        EditPostEvent(
          postId: widget.post['id'].toString(),
          content: content.isEmpty ? null : content,
          imageUrls: oldUrls,
          documentId: _attachedDocument?['id']?.toString(),
          visibility: _selectedVisibility,
          taggedUserIds: _taggedUsers.map((e) => e['id'].toString()).toList(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final displayName = currentUser?.fullName ?? 'Bạn';
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final avatarUrl = currentUser?.avatarUrl;
    
    return BlocListener<FeedBloc, FeedState>(
      listener: (context, state) {
        if (state is PostEdited) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Sửa bài viết thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(state.post); // Trả về màn trước
        } else if (state is PostEditError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${state.message}'), backgroundColor: Colors.red),
          );
        } else if (state is ImagesUploaded) {
          final content = _contentController.text.trim();
          final oldUrls = _currentImages.whereType<String>().toList();
          context.read<FeedBloc>().add(
            EditPostEvent(
              postId: widget.post['id'].toString(),
              content: content.isEmpty ? null : content,
              imageUrls: [...oldUrls, ...state.urls],
              documentId: _attachedDocument?['id']?.toString(),
              visibility: _selectedVisibility,
              taggedUserIds: _taggedUsers.map((e) => e['id'].toString()).toList(),
            ),
          );
        } else if (state is ImagesUploadError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải ảnh mới: ${state.message}'), backgroundColor: Colors.red),
          );
        } else if (state is PostEditing || state is ImagesUploading) {
          if (!_isSubmitting) setState(() => _isSubmitting = true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 80,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          title: Text(
            'Sửa bài đăng',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _isSubmitting
                ? BlocBuilder<FeedBloc, FeedState>(
                    builder: (context, state) {
                      String loadingText = 'Đang đăng...';
                      if (state is ImagesUploading) {
                        loadingText = 'Đang up ảnh...';
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14, 
                              height: 14, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            ),
                            const SizedBox(width: 8),
                            Text(
                              loadingText,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : TextButton(
                    onPressed: _canSubmit ? _submit : null,
                style: TextButton.styleFrom(
                  backgroundColor: _canSubmit 
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : theme.colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Lưu',
                  style: TextStyle(
                    color: _canSubmit ? theme.colorScheme.primary : theme.colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Row
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (avatarUrl != null)
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(avatarUrl),
                      )
                    else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final result = await showModalBottomSheet<PostVisibility>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => PostVisibilityBottomSheet(
                            currentVisibility: _selectedVisibility,
                          ),
                        );
                        if (result != null) {
                          setState(() => _selectedVisibility = result);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(_selectedVisibility.icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              _selectedVisibility.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.expand_more, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (_taggedUsers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text('— cùng với', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                  ..._taggedUsers.map((user) => Chip(
                    label: Text(user['full_name'] ?? user['username'] ?? 'User', style: const TextStyle(fontSize: 12)),
                    onDeleted: () => setState(() => _taggedUsers.remove(user)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  )),
                ],
              ),
            ],

            const SizedBox(height: 16),
            
            // Text Input
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              maxLength: 2000,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // Ẩn counter mặc định
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: _currentImages.isEmpty && _attachedDocument == null 
                    ? 'Bạn đang nghĩ gì?' 
                    : 'Thêm mô tả...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.outline,
                ),
                border: InputBorder.none,
              ),
            ),
            
            // Character counter custom
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_contentController.text.length}/2000',
                style: TextStyle(
                  color: _contentController.text.length > 1800 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            if (_currentImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageGrid(),
            ],
            
            const SizedBox(height: 16),
            
            if (_attachedDocument != null) ...[
              const SizedBox(height: 16),
              AttachedDocumentCard(
                document: _attachedDocument!,
                onRemove: () => setState(() => _attachedDocument = null),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Action Bar
            Text(
              'THÊM VÀO BÀI VIẾT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outlineVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _ActionBtn(
                  icon: Icons.image,
                  label: 'Ảnh',
                  color: theme.colorScheme.primary,
                  onTap: _pickImages,
                ),
                _ActionBtn(
                  icon: Icons.description,
                  label: 'Tài liệu',
                  color: theme.colorScheme.tertiary,
                  onTap: () async {
                    if (_attachedDocument != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chỉ được đính kèm 1 tài liệu')),
                      );
                      return;
                    }
                    final doc = await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const DocumentPickerBottomSheet(),
                    );
                    if (doc != null) {
                      setState(() => _attachedDocument = doc);
                    }
                  },
                ),
                _ActionBtn(
                  icon: Icons.person_add,
                  label: 'Tag',
                  color: theme.colorScheme.secondary,
                  onTap: () async {
                    final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const TagUserBottomSheet(),
                    );
                    if (result != null) {
                      setState(() {
                        // Tránh trùng lặp
                        for (var user in result) {
                          if (!_taggedUsers.any((e) => e['id'] == user['id'])) {
                            _taggedUsers.add(user);
                          }
                        }
                      });
                    }
                  },
                ),
                _ActionBtn(
                  icon: Icons.location_on,
                  label: 'Địa điểm',
                  color: theme.colorScheme.error,
                ),
              ],
            ),
            
          ],
        ),
      ),
    ),
  );
}

  Widget _buildImageGrid() {
    if (_currentImages.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          _buildGridContent(),
        ],
      ),
    );
  }

  Widget _buildGridContent() {
    final count = _currentImages.length;
    final h = 300.0; // Fixed height for grid

    if (count == 1) {
      return SizedBox(
        height: h,
        width: double.infinity,
        child: _buildImageItem(0),
      );
    } else if (count == 2) {
      return SizedBox(
        height: h,
        child: Row(
          children: [
            Expanded(child: _buildImageItem(0)),
            const SizedBox(width: 2),
            Expanded(child: _buildImageItem(1)),
          ],
        ),
      );
    } else if (count == 3) {
      return SizedBox(
        height: h,
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildImageItem(0)),
            const SizedBox(width: 2),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: _buildImageItem(1)),
                  const SizedBox(height: 2),
                  Expanded(child: _buildImageItem(2)),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (count == 4) {
      return SizedBox(
        height: h,
        child: Column(
          children: [
            Expanded(flex: 2, child: _buildImageItem(0)),
            const SizedBox(height: 2),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: _buildImageItem(1)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImageItem(2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImageItem(3)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 5 images
      return SizedBox(
        height: h,
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _buildImageItem(0)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImageItem(1)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(child: _buildImageItem(2)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImageItem(3)),
                  const SizedBox(width: 2),
                  Expanded(child: _buildImageItem(4)),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImageItem(int index) {
    final image = _currentImages[index];
    Widget imageWidget;

    if (image is String) {
      imageWidget = Image.network(image, fit: BoxFit.cover);
    } else if (image is XFile) {
      imageWidget = kIsWeb
          ? Image.network(image.path, fit: BoxFit.cover)
          : Image.file(File(image.path), fit: BoxFit.cover);
    } else {
      imageWidget = const SizedBox();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _currentImages.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
