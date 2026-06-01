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

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  PostVisibility _selectedVisibility = PostVisibility.public;
  Map<String, dynamic>? _attachedDocument;

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ được chọn tối đa 5 ảnh')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
        if (_selectedImages.length > 5) {
          _selectedImages.removeRange(5, _selectedImages.length);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã giới hạn tối đa 5 ảnh')),
          );
        }
      });
    }
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty && _attachedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm nội dung, ảnh hoặc tài liệu trước khi đăng')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (_selectedImages.isNotEmpty) {
      context.read<FeedBloc>().add(
        UploadImagesEvent(files: _selectedImages),
      );
    } else {
      context.read<FeedBloc>().add(
        CreatePostEvent(
          content: content.isEmpty ? null : content,
          documentId: _attachedDocument?['id']?.toString(),
          visibility: _selectedVisibility,
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
        if (state is PostCreated) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Đăng bài thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else if (state is PostCreateError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${state.message}'), backgroundColor: Colors.red),
          );
        } else if (state is ImagesUploaded) {
          final content = _contentController.text.trim();
          context.read<FeedBloc>().add(
            CreatePostEvent(
              content: content.isEmpty ? null : content,
              imageUrls: state.urls,
              documentId: _attachedDocument?['id']?.toString(),
              visibility: _selectedVisibility,
            ),
          );
        } else if (state is ImagesUploadError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải ảnh: ${state.message}'), backgroundColor: Colors.red),
          );
        } else if (state is PostCreating || state is ImagesUploading) {
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
            'Tạo bài đăng',
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
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    ),
                  )
                : TextButton(
                    onPressed: _submit,
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Đăng',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
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
            
            const SizedBox(height: 24),
            
            // Text Input
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              style: TextStyle(
                fontSize: 18,
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Bạn đang nghĩ gì?',
                hintStyle: TextStyle(
                  color: theme.colorScheme.outline,
                ),
                border: InputBorder.none,
              ),
            ),
            
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  _selectedImages[i].path,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImages[i].path),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
