import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String? message;
  final String time;
  final bool isRead;
  final bool isFile;
  final String? fileUrl;
  final String? fileName;
  final String? fileSizeAndType;
  final bool isTop;
  final bool isBottom;
  final bool showAvatar;
  final String? avatarInitials;
  final VoidCallback? onCallPressed;

  const ChatBubble({
    super.key,
    required this.isMe,
    this.message,
    required this.time,
    this.isRead = false,
    this.isFile = false,
    this.fileUrl,
    this.fileName,
    this.fileSizeAndType,
    this.isTop = true,
    this.isBottom = true,
    this.showAvatar = false,
    this.avatarInitials,
    this.onCallPressed,
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
    final isCallHistory = !isFile && message != null && message!.startsWith('[CALL_HISTORY]:');
    final isImage = isFile && fileUrl != null && _isImageUrl(fileUrl!);

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
        else if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: Radius.circular(isTop ? 16 : 4),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(4),
            ),
            child: Image.network(
              fileUrl!,
              width: 240,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) => progress == null
                  ? child
                  : Container(
                      width: 240,
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
              errorBuilder: (ctx, _, __) => Container(
                width: 240,
                height: 180,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
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
            child: isCallHistory 
                ? _buildCallHistoryCard(theme)
                : Text(
                    message ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
          ),
        if (isBottom && !isCallHistory) ...[
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
    final isCallHistory = !isFile && message != null && message!.startsWith('[CALL_HISTORY]:');
    final isImage = isFile && fileUrl != null && _isImageUrl(fileUrl!);

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
              child: isCallHistory 
                  ? _buildCallHistoryCard(theme)
                  : (isImage ? _buildOtherImageBubble(theme) : (isFile ? _buildOtherFileBubble(theme) : Text(
                      message ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ))),
            ),
          ],
        ),
        if (isBottom && !isCallHistory) ...[
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

  Widget _buildCallHistoryCard(ThemeData theme) {
    List<String> parts = message!.split(':');
    final type = parts.length > 1 ? parts[1] : 'VOICE';
    final status = parts.length > 2 ? parts[2] : 'MISSED';

    final isMissed = status == 'MISSED' || status == 'REJECTED';
    final isVideo = type == 'VIDEO';

    String statusText = '';
    if (isMissed) {
      statusText = isVideo ? 'Cuộc gọi video nhỡ' : 'Cuộc gọi nhỡ';
    } else {
      final seconds = int.tryParse(status) ?? 0;
      final m = (seconds / 60).floor().toString().padLeft(2, '0');
      final s = (seconds % 60).toString().padLeft(2, '0');
      statusText = isVideo ? 'Cuộc gọi video - $m:$s' : 'Cuộc gọi thoại - $m:$s';
    }

    final color = isMissed ? Colors.red.shade400 : const Color(0xFF4F46E5);
    final icon = isMissed 
        ? (isVideo ? Icons.missed_video_call : Icons.phone_missed) 
        : (isVideo ? Icons.videocam : Icons.call);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: isMe 
                        ? (isMissed ? Colors.red.shade100 : Colors.white)
                        : (isMissed ? Colors.red.shade700 : theme.colorScheme.onSurface),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : theme.colorScheme.outline, 
                    fontSize: 12
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onCallPressed,
            icon: Icon(isVideo ? Icons.videocam : Icons.call, size: 16),
            label: const Text('Gọi lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isMe ? Colors.white24 : color.withValues(alpha: 0.1),
              foregroundColor: isMe ? Colors.white : color,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherFileBubble(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3730A3).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.picture_as_pdf, color: Color(0xFF3730A3), size: 24),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName ?? '',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                fileSizeAndType ?? '',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherImageBubble(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4), // Container đã có radius
      child: Image.network(
        fileUrl!,
        width: 220,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) => progress == null
            ? child
            : Container(
                width: 220,
                height: 160,
                color: Colors.grey.shade200,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
        errorBuilder: (ctx, _, __) => Container(
          width: 220,
          height: 160,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}
