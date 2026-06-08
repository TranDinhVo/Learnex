import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/room_model.dart';
import '../../../../../shared/widgets/custom_avatar.dart';

class RoomMessageBubble extends StatelessWidget {
  final RoomMessageModel message;
  final bool isMe;
  final bool showAvatar;

  const RoomMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (message.content != null) {
      if (message.content!.startsWith('[SYSTEM]:user_joined:')) {
        final parts = message.content!.split(':');
        final name = parts.length > 3 ? parts[3] : 'Ai đó';
        return _buildSystemMessage(context, '$name vừa tham gia nhóm.', message.createdAt);
      }
      if (message.content!.startsWith('[SYSTEM]:user_kicked:')) {
        final parts = message.content!.split(':');
        final targetName = parts.length > 3 ? parts[3] : 'Ai đó';
        final requesterName = parts.length > 5 ? parts[5] : 'Quản trị viên';
        return _buildSystemMessage(context, '$requesterName đã xoá $targetName khỏi nhóm.', message.createdAt);
      }
      if (message.content!.startsWith('[CALL_HISTORY]:')) {
        return _buildCallHistory(context, message.content!, message.createdAt);
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CustomAvatar(
                  imageUrl: message.senderAvatar,
                  name: message.senderName ?? 'User',
                  radius: 16,
                ),
              )
            else
              const SizedBox(width: 40), // 32 (avatar) + 8 (padding)
          
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.senderName ?? 'User',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(16),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.fileUrl != null)
                        _buildFileCard(context, message.fileUrl!),
                        
                      if (message.content != null && message.content!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: message.fileUrl != null ? 8 : 0),
                          child: Text(
                            message.content!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(
                    DateFormat('HH:mm').format(message.createdAt.toLocal()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadFile(BuildContext context, String url) async {
    String downloadUrl = url;
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
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở file. Vui lòng thử lại.')),
          );
        }
      }
    }
  }

  Widget _buildFileCard(BuildContext context, String fileUrl) {
    final theme = Theme.of(context);
    final isImage = _isImageUrl(fileUrl);

    if (isImage) {
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
                    child: Image.network(fileUrl),
                  ),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fileUrl,
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
        ),
      );
    }

    final fileName = Uri.parse(fileUrl).pathSegments.last;
    
    return GestureDetector(
      onTap: () => _downloadFile(context, fileUrl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                fileName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.download,
              size: 20,
              color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
            ),
          ],
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

  Widget _buildSystemMessage(BuildContext context, String text, DateTime? createdAt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ),
            if (createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTime(createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.black38),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallHistory(BuildContext context, String content, DateTime? createdAt) {
    final parts = content.split(':');
    final isMissed = parts.length > 2 && parts[2] == 'MISSED';
    final duration = !isMissed && parts.length > 2 ? _formatDuration(int.tryParse(parts[2]) ?? 0) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMissed ? Colors.red.shade50 : Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isMissed ? Colors.red.shade100 : Colors.indigo.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isMissed ? Colors.red.shade100 : Colors.indigo.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMissed ? Icons.call_missed : Icons.video_call,
                  size: 16,
                  color: isMissed ? Colors.red : Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMissed ? 'Cuộc gọi nhóm nhỡ' : 'Cuộc gọi nhóm kết thúc',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isMissed ? Colors.red.shade700 : Colors.indigo.shade700,
                    ),
                  ),
                  if (!isMissed)
                    Text(
                      'Thời gian: $duration',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  if (createdAt != null)
                    Text(
                      _formatTime(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMissed ? Colors.red.shade300 : Colors.indigo.shade300,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds giây';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '$m phút $s giây' : '$m phút';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }
}
