import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../../../../app/di.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/webrtc_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../shared/widgets/media_picker_sheet.dart';
import 'package:image_picker/image_picker.dart'; // XFile - works on Web & Mobile
import 'p2p_call_screen.dart';

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
  bool _isLoadingMore = false;
  bool _isUploading = false;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(
          LoadMessagesEvent(conversationId: widget.conversationId),
        );
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onMessageChanged);
  }

  void _onMessageChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      context.read<ChatBloc>().add(SendTypingEvent(targetId: widget.conversationId));
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatBloc>().add(SendStopTypingEvent(targetId: widget.conversationId));
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ChatBloc>().state;
      if (state is MessagesLoaded && state.hasMore && !_isLoadingMore) {
        setState(() => _isLoadingMore = true);
        context.read<ChatBloc>().add(
              LoadMoreMessagesEvent(conversationId: widget.conversationId),
            );
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTyping) {
      context.read<ChatBloc>().add(SendStopTypingEvent(targetId: widget.conversationId));
    }
    _messageController.removeListener(_onMessageChanged);
    _scrollController.removeListener(_onScroll);
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

  void _startCall(String callType) {
    final authState = context.read<AuthBloc>().state;
    String senderId = '';
    String senderName = '';
    if (authState is Authenticated) {
      senderId = authState.user.id;
      senderName = authState.user.fullName.isNotEmpty ? authState.user.fullName : 'Người dùng';
    }

    final roomId = 'call_${senderId}_${widget.conversationId}_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Gửi lời mời gọi
    getIt<WebSocketService>().send({
      'type': 'private_call_invite',
      'data': {
        'targetId': widget.conversationId,
        'callType': callType,
        'roomId': roomId,
        'callerName': senderName,
      }
    });

    // 2. Mở màn hình cuộc gọi ngay
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => P2PCallScreen(
          webrtcService: getIt<WebRTCService>(),
          roomId: roomId,
          partnerName: widget.partnerName,
          partnerId: widget.conversationId,
          isAudioOnly: callType == 'voice',
          isCaller: true,
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(SendMessageEvent(
      conversationId: widget.conversationId,
      content: text,
    ));

    _messageController.clear();
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      context.read<ChatBloc>().add(SendStopTypingEvent(targetId: widget.conversationId));
    }
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _openMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MediaPickerSheet(
        onImagePicked: (file) => _uploadAndSend(file, isImage: true),
        onFilePicked: (file) => _uploadAndSend(file, isImage: false),
      ),
    );
  }

  Future<void> _uploadAndSend(XFile file, {required bool isImage}) async {
    setState(() => _isUploading = true);
    try {
      final service = getIt<MediaUploadService>();
      final fileUrl = isImage
          ? await service.uploadImage(file)
          : (await service.uploadDocument(file))['url'];

      if (!mounted) return;
      context.read<ChatBloc>().add(SendMessageEvent(
        conversationId: widget.conversationId,
        fileUrl: fileUrl,
      ));
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload thất bại: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }


  void _showMessageContextMenu(BuildContext context, String messageId, bool isMe, String? currentContent) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['❤️', '👍', '😆', '😮', '😢', '😡'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        context.read<ChatBloc>().add(
                          ToggleReactionEvent(messageId: messageId, emoji: emoji),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              if (isMe && currentContent != null)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Chỉnh sửa tin nhắn'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context, messageId, currentContent);
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Thu hồi với mọi người', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<ChatBloc>().add(
                      DeleteMessageEvent(messageId: messageId, type: 'for_everyone'),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.grey),
                title: const Text('Gỡ ở phía tôi', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChatBloc>().add(
                    DeleteMessageEvent(messageId: messageId, type: 'for_me'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String messageId, String currentContent) {
    final TextEditingController editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Chỉnh sửa tin nhắn'),
          content: TextField(
            controller: editController,
            autofocus: true,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Nhập nội dung mới...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty && newContent != currentContent) {
                  context.read<ChatBloc>().add(
                    EditMessageEvent(messageId: messageId, content: newContent),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is Authenticated ? authState.user.id : '';
    final initials = widget.partnerName.isNotEmpty
        ? widget.partnerName[0].toUpperCase()
        : 'U';

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        bool isOnline = false;
        bool isPeerTyping = false;

        if (state is MessagesLoaded) {
          isOnline = state.onlineUserIds.contains(widget.conversationId);
          isPeerTyping = state.typingUsers.contains(widget.conversationId);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(context, theme, initials, isOnline),
          body: Column(
            children: [
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state is MessagesLoaded) {
                      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                    }
                  },
                  builder: (context, state) {
                    if (state is ChatInitial || state is ChatLoading) {
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
                    bool hasMore = false;
                    if (state is MessagesLoaded) {
                      messages = state.messages;
                      hasMore = state.hasMore;
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
                  itemCount: messages.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final msg = messages[index] as Map<String, dynamic>;
                    final senderId = msg['sender_id']?.toString() ?? '';
                    final isMe = senderId == currentUserId;
                    final content = msg['content']?.toString();
                    final fileUrl = msg['file_url']?.toString();
                    final createdAt = msg['created_at']?.toString();
                    
                    bool isTop = true;
                    if (index + 1 < messages.length) {
                      final nextMsg = messages[index + 1] as Map<String, dynamic>;
                      if (nextMsg['sender_id']?.toString() == senderId) isTop = false;
                    }

                    bool isBottom = true;
                    if (index - 1 >= 0) {
                      final prevMsg = messages[index - 1] as Map<String, dynamic>;
                      if (prevMsg['sender_id']?.toString() == senderId) isBottom = false;
                    }

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

                      final hasFile = fileUrl != null && fileUrl.isNotEmpty;
                      // Parse call history
                      final isCallHistory = !hasFile && content != null && content.startsWith('[CALL_HISTORY]:');
                      String? callHistoryType;
                      if (isCallHistory) {
                        final parts = content.split(':');
                        callHistoryType = parts.length > 1 ? parts[1] : 'VOICE';
                      }

                      final isDeleted = msg['is_deleted'] == true;
                      final isEdited = msg['edited_at'] != null;
                      final messageId = msg['id']?.toString() ?? '';

                      final bubble = GestureDetector(
                        onLongPress: () {
                          if (isDeleted) return;
                          _showMessageContextMenu(context, messageId, isMe, content);
                        },
                        onSecondaryTapDown: (details) {
                          if (isDeleted) return;
                          _showMessageContextMenu(context, messageId, isMe, content);
                        },
                        child: ChatBubble(
                          isMe: isMe,
                          message: content,
                          time: timeStr,
                          isRead: msg['is_read'] == true,
                          isFile: hasFile,
                          fileUrl: fileUrl,
                          fileName: hasFile ? fileUrl.split('/').last : null,
                          fileSizeAndType: hasFile ? 'Tập tin đính kèm' : null,
                          isTop: isTop,
                          isBottom: isBottom,
                          showAvatar: !isMe && isBottom,
                          avatarInitials: initials,
                          isDeleted: isDeleted,
                          isEdited: isEdited,
                          reactions: msg['reactions'],
                          onCallPressed: isCallHistory
                              ? () => _startCall(callHistoryType == 'VIDEO' ? 'video' : 'voice')
                              : null,
                        ),
                      );

                      if (index == messages.length - 1) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7E8E9), // surface-container-high
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Hôm nay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF464555), // on-surface-variant
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            bubble,
                          ],
                        );
                      }
                      return bubble;
                  },
                );
              },
            ),
          ),

          // Typing Indicator
          if (isPeerTyping)
            TypingIndicatorBubble(initials: initials),

          // Input Bar
          _buildInputBar(theme),
        ],
      ),
    );
  });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme, String initials, bool isOnline) {
    return AppBar(
      backgroundColor: const Color(0xCCF8FAFC), // slate-50/80
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 48,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF464555), size: 20),
        onPressed: () {
          // Reload danh sách hội thoại trước khi quay lại
          context.read<ChatBloc>().add(LoadConversationsEvent());
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/chat');
          }
        },
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
                  color: const Color(0xFFB6B4FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF140F54),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isOnline)
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
                  isOnline ? 'Đang online' : 'Ngoại tuyến',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green.shade500 : Colors.grey,
                    fontWeight: FontWeight.normal,
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
          onPressed: () => _startCall('voice'),
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: Color(0xFF777587)),
          onPressed: () => _startCall('video'),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF777587)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Column(
      children: [
        if (_isUploading)
          LinearProgressIndicator(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
            minHeight: 2,
          ),
        Container(
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
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF464555), size: 26),
                onPressed: _isUploading ? null : _openMediaPicker,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: _isUploading ? null : (_) => _sendMessage(),
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
                decoration: BoxDecoration(
                  color: _isUploading ? Colors.grey : const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _isUploading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
