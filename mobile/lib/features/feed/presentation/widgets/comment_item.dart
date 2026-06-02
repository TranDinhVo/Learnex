import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  final String authorName;
  final String authorInitials;
  final String timeAgo;
  final String content;
  final Color avatarColor;
  final Color avatarTextColor;
  final String? authorAvatarUrl;
  final bool isEdited;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onEditTap;
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onLikeTap;
  final VoidCallback? onReplyTap;
  final bool isReply;
  final VoidCallback? onAuthorTap;
  final int depth;

  const CommentItem({
    super.key,
    required this.authorName,
    required this.authorInitials,
    required this.timeAgo,
    required this.content,
    required this.avatarColor,
    required this.avatarTextColor,
    this.authorAvatarUrl,
    this.isEdited = false,
    this.onDeleteTap,
    this.onEditTap,
    this.isLiked = false,
    this.likeCount = 0,
    this.onLikeTap,
    this.onReplyTap,
    this.isReply = false,
    this.onAuthorTap,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Indent 40px for depth=1, 80px for depth=2, up to max depth 3.
    final leftPadding = depth > 0 ? (depth * 32.0) : 0.0;
    
    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onAuthorTap,
            child: Container(
              width: isReply ? 28 : 36,
              height: isReply ? 28 : 36,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
                image: authorAvatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(authorAvatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
            ),
            alignment: Alignment.center,
            child: authorAvatarUrl == null
                ? Text(
                    authorInitials,
                    style: TextStyle(
                      fontSize: isReply ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: avatarTextColor,
                    ),
                  )
                : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: (onDeleteTap != null || onEditTap != null) ? () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEditTap != null)
                            ListTile(
                              leading: const Icon(Icons.edit_outlined, color: Colors.indigo),
                              title: const Text('Chỉnh sửa bình luận', style: TextStyle(color: Colors.indigo)),
                              onTap: () {
                                Navigator.pop(context);
                                onEditTap!();
                              },
                            ),
                          if (onDeleteTap != null)
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: const Text('Xóa bình luận', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                onDeleteTap!();
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Expanded(
                           child: GestureDetector(
                             onTap: onAuthorTap,
                             child: Text(
                               authorName,
                               style: TextStyle(
                                 fontSize: 14,
                                 fontWeight: FontWeight.bold,
                                 color: theme.colorScheme.onSurface,
                               ),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ),
                        Text(
                          isEdited ? '$timeAgo (đã chỉnh sửa)' : timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: onLikeTap,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      likeCount > 0 ? 'Thích · $likeCount' : 'Thích',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                        color: isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: onReplyTap,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Phản hồi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
