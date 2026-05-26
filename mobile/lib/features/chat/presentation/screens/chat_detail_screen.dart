import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learnex/shared/utils/date_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String partnerName;

  const ChatDetailScreen({
    super.key,
    this.conversationId = '',
    this.partnerName = 'Học viên',
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load conversations messages
    context.read<ChatBloc>().add(LoadMessagesEvent(conversationId: widget.conversationId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(SendMessageEvent(
      conversationId: widget.conversationId,
      content: text,
    ));

    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : '';
    final initials = widget.partnerName.isNotEmpty
        ? widget.partnerName[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, theme, initials),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessagesLoaded || state is MessageSent) {
                  Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatBloc>().add(
                              LoadMessagesEvent(conversationId: widget.conversationId),
                            );
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                List<dynamic> messages = [];
                if (state is MessagesLoaded) {
                  messages = state.messages;
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có tin nhắn nào',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hãy gửi tin nhắn đầu tiên để bắt đầu cuộc trò chuyện!',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Display latest messages at the bottom
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index] as Map<String, dynamic>;
                    final isMe = msg['sender_id']?.toString() == currentUserId;
                    final content = msg['content']?.toString();
                    final fileUrl = msg['file_url']?.toString();
                    final createdAt = msg['created_at']?.toString();
                    
                    // Parse date formatted time
                    String timeStr = 'Vừa xong';
                    if (createdAt != null) {
                      try {
                        final dateTime = DateTime.parse(createdAt).toLocal();
                        final min = dateTime.minute.toString().padLeft(2, '0');
                        final period = dateTime.hour >= 12 ? 'CH' : 'SA';
                        final displayHour = dateTime.hour > 12 
                            ? dateTime.hour - 12 
                            : (dateTime.hour == 0 ? 12 : dateTime.hour);
                        timeStr = '$displayHour:$min $period';
                      } catch (_) {}
                    }

                    return ChatBubble(
                      isMe: isMe,
                      message: content,
                      time: timeStr,
                      isRead: msg['is_read'] == true,
                      isFile: fileUrl != null,
                      fileName: fileUrl != null ? fileUrl.split('/').last : null,
                      fileSizeAndType: fileUrl != null ? 'Tập tin đính kèm' : null,
                    );
                  },
                );
              },
            ),
          ),

          // Input Bar
          _buildInputBar(theme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme, String initials) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4F46E5), size: 20),
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
                  color: const Color(0xFFEDEEFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF3123CC),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partnerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF191C1D),
                  ),
                ),
                Text(
                  'Đang hoạt động',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call, color: Color(0xFF777587)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: Color(0xFF777587)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF777587)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF4F46E5), size: 26),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: const TextStyle(color: Color(0xFF777587), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
