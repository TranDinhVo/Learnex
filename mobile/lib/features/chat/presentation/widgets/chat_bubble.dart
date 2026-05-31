import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String? message;
  final String time;
  final bool isRead;
  final bool isFile;
  final String? fileName;
  final String? fileSizeAndType;
  final bool isTop;
  final bool isBottom;
  final bool showAvatar;
  final String? avatarInitials;

  const ChatBubble({
    super.key,
    required this.isMe,
    this.message,
    required this.time,
    this.isRead = false,
    this.isFile = false,
    this.fileName,
    this.fileSizeAndType,
    this.isTop = true,
    this.isBottom = true,
    this.showAvatar = false,
    this.avatarInitials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isBottom ? 16.0 : 2.0),
      child: isMe ? _buildMyBubble(theme) : _buildOtherBubble(theme),
    );
  }

  Widget _buildMyBubble(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isFile)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3730A3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: Radius.circular(isTop ? 16 : 4),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 280),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        fileSizeAndType ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: Radius.circular(isTop ? 16 : 4),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(4),
              ),
              boxShadow: [
                if (isBottom)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              message ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        if (isBottom) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isRead ? Icons.done_all : Icons.check,
                size: 14,
                color: isRead ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOtherBubble(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAvatar)
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB6B4FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarInitials ?? 'U',
                  style: const TextStyle(color: Color(0xFF140F54), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            else
              const SizedBox(width: 36),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTop ? 16 : 4),
                  topRight: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                  bottomLeft: const Radius.circular(4),
                ),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                boxShadow: [
                  if (isBottom)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                    ),
                ],
              ),
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (isBottom) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 36.0),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
