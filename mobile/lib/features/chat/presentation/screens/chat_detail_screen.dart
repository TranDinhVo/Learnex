import 'package:flutter/material.dart';
import '../widgets/chat_bubble.dart';

class _Message {
  final bool isMe;
  final String? text;
  final String time;
  final bool isRead;
  final bool isFile;
  final String? fileName;
  final String? fileSizeAndType;

  _Message({
    required this.isMe,
    this.text,
    required this.time,
    this.isRead = false,
    this.isFile = false,
    this.fileName,
    this.fileSizeAndType,
  });
}

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final List<_Message> _messages = [
    _Message(isMe: false, text: 'Bạn có tài liệu CNPM không? Mình đang cần gấp', time: '9:30 SA'),
    _Message(isMe: true, text: 'Có bạn ơi! Mình sẽ gửi ngay cho bạn', time: '9:31 SA', isRead: true),
    _Message(isMe: true, isFile: true, fileName: 'CNPM_Slides.pdf', fileSizeAndType: '3.1 MB · PDF', time: '9:31 SA', isRead: true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: _messages.length + 2,
              itemBuilder: (context, index) {
                // First element is Date Separator
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Hôm nay',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Last element is Typing Indicator
                if (index == _messages.length + 1) {
                  return _TypingIndicator(theme: theme);
                }

                // Actual message bubbles
                final msg = _messages[index - 1];
                return ChatBubble(
                  isMe: msg.isMe,
                  message: msg.text,
                  time: msg.time,
                  isRead: msg.isRead,
                  isFile: msg.isFile,
                  fileName: msg.fileName,
                  fileSizeAndType: msg.fileSizeAndType,
                );
              },
            ),
          ),

          // Input Bar
          _InputBar(theme: theme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 48,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurfaceVariant, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'AN',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
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
                'Anh Nam',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Đang online',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: Icon(Icons.call, color: theme.colorScheme.onSurfaceVariant), onPressed: () {}),
        IconButton(icon: Icon(Icons.videocam, color: theme.colorScheme.onSurfaceVariant), onPressed: () {}),
        IconButton(icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant), onPressed: () {}),
      ],
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final ThemeData theme;

  const _TypingIndicator({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            'AN',
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(),
                  _buildTypingDot(),
                  _buildTypingDot(),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Đang nhập...',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypingDot() {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: Color(0xFF777587),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final ThemeData theme;

  const _InputBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.colorScheme.onSurfaceVariant, size: 26),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Nhắn tin...',
                  hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.onPrimaryContainer, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
