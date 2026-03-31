import 'package:flutter/material.dart';

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
  final String? imageUrl;
  final int likes;
  final int comments;

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
    this.imageUrl,
    required this.likes,
    required this.comments,
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
                _buildHeader(theme),
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
                  _buildDocumentAttachment(theme),
                ],
              ],
            ),
          ),
          if (postType == PostType.image && imageUrl != null) ...[
            Image.network(
              imageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 0),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: _buildFooter(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
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
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$authorHandle · $timeAgo',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDocumentAttachment(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    documentName ?? 'Tài liệu',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    documentSize ?? '0 MB',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$likes lượt thích · $comments bình luận',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionLabel(Icons.favorite, 'Thích', theme.colorScheme.primary),
            _buildActionLabel(Icons.chat_bubble_outline, 'Bình luận', theme.colorScheme.onSurfaceVariant),
            _buildActionLabel(Icons.bookmark_outline, '', theme.colorScheme.onSurfaceVariant),
            _buildActionLabel(Icons.share, '', theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ],
    );
  }

  Widget _buildActionLabel(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        if (label.isNotEmpty) const SizedBox(width: 8),
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
      ],
    );
  }
}
