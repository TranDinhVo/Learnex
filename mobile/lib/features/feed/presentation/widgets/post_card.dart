import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/utils/file_icon_helper.dart';

enum PostType { document, image, text }

class PostCard extends StatelessWidget {
  final String authorName;
  final String authorHandle;
  final String timeAgo;
  final String authorInitials;
  final Color avatarColor;
  final Color avatarTextColor;
  final String content;
  final PostType postType;
  final String? documentName;
  final String? documentSize;
  final String? documentUrl;
  final List<String>? imageUrls;
  final List<dynamic>? taggedUsers;
  final String? location;
  final int likes;
  final int comments;
  final VoidCallback? onAuthorTap;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onSaveTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onDeleteTap;
  final String? authorAvatarUrl;
  final VoidCallback? onEditTap;
  final String? visibility;
  final Function(String)? onTaggedUserTap;
  final VoidCallback? onLikersTap;

  const PostCard({
    super.key,
    required this.authorName,
    required this.authorHandle,
    required this.timeAgo,
    required this.authorInitials,
    required this.avatarColor,
    required this.avatarTextColor,
    required this.content,
    this.postType = PostType.text,
    this.documentName,
    this.documentSize,
    this.documentUrl,
    this.imageUrls,
    this.taggedUsers,
    this.location,
    this.authorAvatarUrl,
    this.visibility,
    required this.likes,
    required this.comments,
    this.onAuthorTap,
    this.isLiked = false,
    this.isSaved = false,
    this.onLikeTap,
    this.onCommentTap,
    this.onSaveTap,
    this.onShareTap,
    this.onMoreTap,
    this.onDeleteTap,
    this.onEditTap,
    this.onTaggedUserTap,
    this.onLikersTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
                if (postType == PostType.document) ...[
                  const SizedBox(height: 12),
                  _buildDocumentAttachment(context, theme),
                ],
              ],
            ),
          ),
          if (postType == PostType.image && imageUrls != null && imageUrls!.isNotEmpty) ...[
            _buildImageGrid(context),
            const SizedBox(height: 0),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: _buildFooter(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: onAuthorTap,
                child: authorAvatarUrl != null
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(authorAvatarUrl!),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: avatarColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          authorInitials,
                          style: TextStyle(
                            color: avatarTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                      children: [
                        TextSpan(
                          text: authorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = onAuthorTap,
                        ),
                        if (taggedUsers != null && taggedUsers!.isNotEmpty) ...[
                          TextSpan(
                            text: ' cùng với ',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          _buildTaggedTextSpans(context, theme),
                        ],
                        if (location != null && location!.isNotEmpty) ...[
                          TextSpan(
                            text: ' tại ',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextSpan(
                            text: location,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$authorHandle · $timeAgo',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (visibility != null) ...[
                        Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(
                          visibility == 'friends'
                              ? Icons.group
                              : (visibility == 'private'
                                  ? Icons.lock
                                  : Icons.public),
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      IconButton(
        icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
          onPressed: onMoreTap ?? () => _showMoreBottomSheet(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  TextSpan _buildTaggedTextSpans(BuildContext context, ThemeData theme) {
    if (taggedUsers == null || taggedUsers!.isEmpty) return const TextSpan();
    final users = taggedUsers!;
    final style = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );

    if (users.length == 1) {
      final name = users.first['full_name'] ?? users.first['username'] ?? 'User';
      final id = users.first['id']?.toString() ?? '';
      return TextSpan(
        text: name,
        style: style,
        recognizer: TapGestureRecognizer()..onTap = () => onTaggedUserTap?.call(id),
      );
    } else if (users.length == 2) {
      final name1 = users[0]['full_name'] ?? users[0]['username'] ?? 'User';
      final id1 = users[0]['id']?.toString() ?? '';
      final name2 = users[1]['full_name'] ?? users[1]['username'] ?? 'User';
      final id2 = users[1]['id']?.toString() ?? '';
      return TextSpan(
        children: [
          TextSpan(
            text: name1,
            style: style,
            recognizer: TapGestureRecognizer()..onTap = () => onTaggedUserTap?.call(id1),
          ),
          TextSpan(text: ' và ', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          TextSpan(
            text: name2,
            style: style,
            recognizer: TapGestureRecognizer()..onTap = () => onTaggedUserTap?.call(id2),
          ),
        ],
      );
    } else {
      final name1 = users.first['full_name'] ?? users.first['username'] ?? 'User';
      final id1 = users.first['id']?.toString() ?? '';
      return TextSpan(
        children: [
          TextSpan(
            text: name1,
            style: style,
            recognizer: TapGestureRecognizer()..onTap = () => onTaggedUserTap?.call(id1),
          ),
          TextSpan(
            text: ' và ${users.length - 1} người khác',
            style: style,
            recognizer: TapGestureRecognizer()..onTap = () => _showTaggedUsersList(context),
          ),
        ],
      );
    }
  }

  void _showTaggedUsersList(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Những người được gắn thẻ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: taggedUsers!.length,
                  itemBuilder: (context, index) {
                    final user = taggedUsers![index];
                    final name = user['full_name'] ?? user['username'] ?? 'User';
                    final id = user['id']?.toString() ?? '';
                    final avatarUrl = user['avatar_url'] as String?;
                    
                    return ListTile(
                      leading: avatarUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(avatarUrl),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onTaggedUserTap?.call(id);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentAttachment(BuildContext context, ThemeData theme) {
    // Derive file type label from URL or name
    String fileExt = 'FILE';
    final src = documentUrl ?? documentName ?? '';
    final extMatch = RegExp(r'\.([a-zA-Z0-9]+)(?:\?|$)').firstMatch(src);
    if (extMatch != null) fileExt = extMatch.group(1)!.toUpperCase();

    final iconData = FileIconHelper.getIcon(documentUrl ?? documentName);
    final iconColor = FileIconHelper.getColor(documentUrl ?? documentName);
    final iconBg = FileIconHelper.getBackgroundColor(documentUrl ?? documentName);

    return InkWell(
      onTap: documentUrl != null
          ? () async {
              String downloadUrl = documentUrl!;
              if (downloadUrl.contains('/raw/upload/')) {
                downloadUrl = downloadUrl.replaceFirst('/raw/upload/', '/raw/upload/fl_attachment/');
              } else if (downloadUrl.contains('/image/upload/')) {
                downloadUrl = downloadUrl.replaceFirst('/image/upload/', '/image/upload/fl_attachment/');
              } else if (downloadUrl.contains('/video/upload/')) {
                downloadUrl = downloadUrl.replaceFirst('/video/upload/', '/video/upload/fl_attachment/');
              }

              final uri = Uri.tryParse(downloadUrl);
              if (uri != null) {
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              }
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.2),
            width: 1,
          ),
          color: iconBg.withValues(alpha: 0.08),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: file type accent strip
            Container(
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fileExt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài liệu học tập',
                      style: TextStyle(
                        fontSize: 11,
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (documentUrl != null)
                    Icon(Icons.open_in_new_rounded, size: 14, color: iconColor),
                ],
              ),
            ),
            // Bottom: file info row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          documentName ?? 'Tài liệu đính kèm',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          documentSize != null ? '📎 $documentSize' : '📎 Nhấn để mở tài liệu',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    final count = imageUrls!.length;
    // Responsive aspect ratio based on image count
    final ratio = count == 1 ? 4 / 3 : (count == 2 ? 2 / 1 : 1 / 1);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 500, // Limit maximum height on wide screens
      ),
      child: AspectRatio(
        aspectRatio: ratio.toDouble(),
        child: Stack(
          children: [
            _buildGridContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent(BuildContext context) {
    final count = imageUrls!.length;
    
    if (count == 1) {
      return SizedBox.expand(child: _buildImageItem(context, 0));
    } else if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageItem(context, 0)),
          const SizedBox(width: 2),
          Expanded(child: _buildImageItem(context, 1)),
        ],
      );
    } else if (count == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _buildImageItem(context, 0)),
          const SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildImageItem(context, 1)),
                const SizedBox(height: 2),
                Expanded(child: _buildImageItem(context, 2)),
              ],
            ),
          ),
        ],
      );
    } else if (count == 4) {
      return Column(
        children: [
          Expanded(flex: 2, child: _buildImageItem(context, 0)),
          const SizedBox(height: 2),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: _buildImageItem(context, 1)),
                const SizedBox(width: 2),
                Expanded(child: _buildImageItem(context, 2)),
                const SizedBox(width: 2),
                Expanded(child: _buildImageItem(context, 3)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 5+ images
      return Column(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: _buildImageItem(context, 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildImageItem(context, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: _buildImageItem(context, 2)),
                const SizedBox(width: 2),
                Expanded(child: _buildImageItem(context, 3)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageItem(context, 4),
                      if (count > 5)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text(
                            '+${count - 5}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImageItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(imageUrls![index]),
                ),
              ),
            ),
          ),
        );
      },
      child: Image.network(
        imageUrls![index],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: '$likes lượt thích',
                    recognizer: TapGestureRecognizer()..onTap = () {
                      if (likes > 0 && onLikersTap != null) onLikersTap!();
                    },
                  ),
                  TextSpan(text: ' · $comments bình luận'),
                ]
              )
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              label: 'Thích',
              color: isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              onTap: onLikeTap,
            ),
            _buildActionButton(
              icon: Icons.chat_bubble_outline,
              label: 'Bình luận',
              color: theme.colorScheme.onSurfaceVariant,
              onTap: onCommentTap,
            ),
            _buildActionButton(
              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
              label: '',
              color: isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              onTap: onSaveTap,
            ),
            _buildActionButton(
              icon: Icons.share,
              label: '',
              color: theme.colorScheme.onSurfaceVariant,
              onTap: onShareTap ?? () => _showShareBottomSheet(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMoreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              if (onEditTap != null)
                _buildBottomSheetTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: 'Chỉnh sửa quyền riêng tư',
                  color: const Color(0xFF4F46E5),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 300), () {
                      onEditTap!();
                    });
                  },
                ),
              if (onDeleteTap != null)
                _buildBottomSheetTile(
                  context,
                  icon: Icons.delete_outline_rounded,
                  label: 'Xóa bài viết',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context);
                  },
                ),
              _buildBottomSheetTile(
                context,
                icon: Icons.copy_rounded,
                label: 'Sao chép liên kết',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép liên kết bài viết vào khay nhớ tạm!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildBottomSheetTile(
                context,
                icon: Icons.report_gmailerrorred_rounded,
                label: 'Báo cáo bài viết',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
              _buildBottomSheetTile(
                context,
                icon: Icons.visibility_off_outlined,
                label: 'Không quan tâm',
                color: const Color(0xFF6B7280),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã ẩn bài viết này khỏi bảng tin của bạn.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Xóa bài viết?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onDeleteTap != null) onDeleteTap!();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Báo cáo bài viết',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Cảm ơn bạn đã phản hồi. Chúng tôi sẽ xem xét bài viết này để đảm bảo môi trường học tập lành mạnh.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chia sẻ bài viết',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1D),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildBottomSheetTile(
                context,
                icon: Icons.link_rounded,
                label: 'Sao chép liên kết',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép liên kết bài viết vào khay nhớ tạm!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildBottomSheetTile(
                context,
                icon: Icons.send_rounded,
                label: 'Chia sẻ qua tin nhắn LearnEx',
                color: const Color(0xFF4F46E5),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng chia sẻ qua chat đang được phát triển.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildBottomSheetTile(
                context,
                icon: Icons.repeat_rounded,
                label: 'Chia sẻ lên Bảng tin của tôi',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã chia sẻ bài viết này lên bảng tin của bạn!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildBottomSheetTile(
                context,
                icon: Icons.share_rounded,
                label: 'Chia sẻ khác...',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang mở bảng chia sẻ hệ thống...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF464555),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
