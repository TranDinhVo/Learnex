import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final bool isDeleted;
  final bool isEdited;
  final Map<String, dynamic>? reactions;

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
    this.isDeleted = false,
    this.isEdited = false,
    this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isBottom ? 16.0 : 2.0),
      child: isMe ? _buildMyBubble(context, theme) : _buildOtherBubble(context, theme),
    );
  }

  void _openFile(BuildContext context, String url) async {
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

  Widget _buildMyBubble(BuildContext context, ThemeData theme) {
    final isCallHistory = !isFile && message != null && message!.startsWith('[CALL_HISTORY]:');
    final isImage = isFile && fileUrl != null && _isImageUrl(fileUrl!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isFile)
          GestureDetector(
            onTap: () {
              if (fileUrl != null) _openFile(context, fileUrl!);
            },
            child: Container(
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
        else if (isCallHistory)
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
            ),
            constraints: const BoxConstraints(maxWidth: 280),
            child: _buildCallHistoryCard(theme),
          )
        else if (isDeleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: const Color(0xFFC7C6D3), width: 1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: Radius.circular(isTop ? 18 : 4),
                bottomLeft: const Radius.circular(18),
                bottomRight: Radius.circular(isBottom ? 18 : 4),
              ),
            ),
            child: const Text(
              'Tin nhắn đã thu hồi',
              style: TextStyle(
                color: Color(0xFF777587),
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3730A3),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: Radius.circular(isTop ? 18 : 4),
                bottomLeft: const Radius.circular(18),
                bottomRight: Radius.circular(isBottom ? 18 : 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                if (isEdited)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      '(đã chỉnh sửa)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (reactions != null && reactions!.isNotEmpty)
          _buildReactionsWidget(),
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

  Widget _buildOtherBubble(BuildContext context, ThemeData theme) {
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
                  : isDeleted
                      ? const Text(
                          'Tin nhắn đã thu hồi',
                          style: TextStyle(
                            color: Color(0xFF777587),
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        )
                      : (isImage ? _buildOtherImageBubble(theme) : (isFile ? GestureDetector(
                          onTap: () {
                            if (fileUrl != null) _openFile(context, fileUrl!);
                          },
                          child: _buildOtherFileBubble(theme),
                        ) : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message ?? '',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            if (isEdited)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '(đã chỉnh sửa)',
                                  style: TextStyle(
                                    color: Color(0xFF777587),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ))),
            ),
          ],
        ),
        if (reactions != null && reactions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 36.0),
            child: _buildReactionsWidget(),
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

  Widget _buildReactionsWidget() {
    if (reactions == null || reactions!.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions!.entries.map((e) {
          final count = (e.value as List).length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 12)),
                if (count > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
