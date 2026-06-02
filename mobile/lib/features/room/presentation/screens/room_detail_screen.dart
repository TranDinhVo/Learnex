import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/webrtc_service.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../../../../shared/widgets/media_picker_sheet.dart';
import 'package:image_picker/image_picker.dart'; // XFile - works on Web & Mobile
import '../screens/call_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/room_detail_bloc.dart';
import '../bloc/room_detail_event.dart';
import '../bloc/room_detail_state.dart';
import '../widgets/room_message_bubble.dart';
import 'room_members_screen.dart';
import 'room_invite_screen.dart';
import 'room_requests_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    this.roomName = 'Phòng Học',
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late RoomDetailBloc _bloc;
  String? _myUserId;
  String? _myRole;
  String? _ownerId;
  String _privacyMode = 'public';
  List<String> _activeCallUsers = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<RoomDetailBloc>();
    _bloc.add(LoadRoomDetailEvent(widget.roomId));
    _bloc.add(LoadMessagesEvent(widget.roomId));
    _bloc.add(LoadMembersEvent(widget.roomId));

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _myUserId = authState.user.id;
    }

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _bloc.add(LoadMoreMessagesEvent(widget.roomId));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _bloc.add(SendMessageEvent(roomId: widget.roomId, content: text));
      _messageController.clear();
      _scrollToBottom();
    }
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
      _bloc.add(SendMessageEvent(
        roomId: widget.roomId,
        fileUrl: fileUrl,
      ));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload thất bại: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _joinCall({bool isAudioOnly = false}) {
    String callerName = 'Người dùng';
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      callerName = authState.user.fullName.isNotEmpty ? authState.user.fullName : authState.user.username;
    }

    getIt<WebSocketService>().send({
      'type': 'start_room_call',
      'data': {
        'roomId': widget.roomId,
        'callerName': callerName,
        'callType': isAudioOnly ? 'voice' : 'video'
      }
    });

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: _bloc,
        child: CallScreen(
          webrtcService: getIt<WebRTCService>(),
          roomId: widget.roomId,
          isAudioOnly: isAudioOnly,
        ),
      ),
    ));
  }

  Widget _buildOngoingCallBanner() {
    if (_activeCallUsers.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _joinCall(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(bottom: BorderSide(color: Colors.green.shade200)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuộc gọi nhóm đang diễn ra',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                  ),
                  Text(
                    'Chạm để tham gia ngay',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.green),
          ],
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Color(0xFF4F46E5)),
              title: const Text('Thành viên phòng'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: _bloc,
                    child: RoomMembersScreen(
                      roomId: widget.roomId,
                      myRole: _myRole ?? 'member',
                      ownerId: _ownerId ?? '',
                    ),
                  ),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt, color: Colors.green),
              title: const Text('Mời thành viên'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: _bloc,
                    child: RoomInviteScreen(roomId: widget.roomId),
                  ),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Rời phòng', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showConfirmLeaveRoom();
              },
            ),
            if (_privacyMode == 'approval' && (_myRole == 'owner' || _myRole == 'moderator'))
              ListTile(
                leading: const Icon(Icons.approval, color: Colors.orange),
                title: const Text('Yêu cầu tham gia'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: _bloc,
                      child: RoomRequestsScreen(roomId: widget.roomId),
                    ),
                  ));
                },
              ),
            if (_myRole == 'owner')
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Giải tán phòng', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showConfirmDeleteRoom();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showConfirmLeaveRoom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời phòng'),
        content: const Text('Bạn có chắc chắn muốn rời khỏi phòng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(LeaveRoomEvent(widget.roomId));
            },
            child: const Text('Rời đi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteRoom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giải tán phòng'),
        content: const Text('Bạn có chắc chắn muốn giải tán phòng này? Toàn bộ tin nhắn và dữ liệu phòng sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(DeleteRoomEvent(widget.roomId));
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<RoomDetailBloc, RoomDetailState>(
        listener: (context, state) {
          if (state is RoomDetailLoaded) {
            _myRole = state.room.userRole;
            _ownerId = state.room.ownerId;
            setState(() {
              _privacyMode = state.room.privacyMode;
            });
            // Yêu cầu trạng thái cuộc gọi hiện tại
            getIt<WebSocketService>().send({
              'type': 'get_room_active_status',
              'data': {'roomId': widget.roomId}
            });
          } else if (state is RoomActiveStatusUpdate) {
            setState(() {
              _activeCallUsers = state.activeUsers;
            });
          } else if (state is RoomDetailLeft) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã rời phòng')));
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is RoomDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã giải tán phòng')));
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is RoomDetailKicked) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn đã bị xoá khỏi phòng', style: TextStyle(color: Colors.red))));
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is RoomDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.red))));
          }
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              BlocBuilder<RoomDetailBloc, RoomDetailState>(
                buildWhen: (p, c) => c is RoomDetailLoaded,
                builder: (context, state) {
                  String? avatarUrl;
                  if (state is RoomDetailLoaded) avatarUrl = state.room.avatarUrl;
                  return CustomAvatar(imageUrl: avatarUrl, name: widget.roomName, radius: 18);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.roomName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.call, color: Color(0xFF4F46E5)), onPressed: () => _joinCall(isAudioOnly: true)),
            IconButton(icon: const Icon(Icons.videocam, color: Color(0xFF4F46E5)), onPressed: () => _joinCall(isAudioOnly: false)),
            IconButton(icon: const Icon(Icons.more_horiz), onPressed: _showMenu),
          ],
        ),
        body: Column(
          children: [
            // Avatar strip (members)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF8F9FA),
              child: BlocBuilder<RoomDetailBloc, RoomDetailState>(
                buildWhen: (p, c) => c is MembersLoaded,
                builder: (context, state) {
                  if (state is MembersLoaded) {
                    final members = state.members;
                    final displayMembers = members.take(4).toList();
                    final remaining = members.length - 4;
                    
                    return Row(
                      children: [
                        for (int i = 0; i < displayMembers.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: CustomAvatar(
                              imageUrl: displayMembers[i].avatarUrl,
                              name: displayMembers[i].fullName ?? displayMembers[i].username ?? 'User',
                              radius: 16,
                              backgroundColor: const Color(0xFF4F46E5),
                              textColor: Colors.white,
                            ),
                          ),
                        if (remaining > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('+$remaining thêm', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                          ),
                      ],
                    );
                  }
                  return const SizedBox(height: 32);
                },
              ),
            ),
            _buildOngoingCallBanner(),
            Expanded(
              child: BlocBuilder<RoomDetailBloc, RoomDetailState>(
                buildWhen: (p, c) => c is MessagesLoaded || c is RoomDetailLoading,
                builder: (context, state) {
                  if (state is RoomDetailLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  List<dynamic> currentMessages = [];
                  if (state is MessagesLoaded) {
                    currentMessages = state.messages;
                  } else {
                    // Cố lấy data từ currentState nếu cast fail
                    if (_bloc.state is MessagesLoaded) {
                       currentMessages = (_bloc.state as MessagesLoaded).messages;
                    }
                  }

                  if (currentMessages.isEmpty) {
                    return const Center(child: Text('Chưa có tin nhắn nào', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: currentMessages.length,
                    itemBuilder: (context, index) {
                      final msg = currentMessages[index];
                      final isMe = msg.senderId == _myUserId;
                      // Logic nhóm ngày và hiển thị avatar có thể làm thêm sau (showAvatar = true)
                      return RoomMessageBubble(
                        message: msg,
                        isMe: isMe,
                        showAvatar: !isMe,
                      );
                    },
                  );
                },
              ),
            ),
            
            // Input Bar
            Column(
              children: [
                if (_isUploading)
                  const LinearProgressIndicator(minHeight: 2),
                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 8,
                    bottom: 8 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF4F46E5)),
                        onPressed: _isUploading ? null : _openMediaPicker,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _messageController,
                            onSubmitted: _isUploading ? null : (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Nhắn tin trong phòng...',
                              border: InputBorder.none,
                              suffixIcon: Icon(Icons.sentiment_satisfied_alt, color: Colors.grey),
                              suffixIconConstraints: BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _isUploading ? Colors.grey : const Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _isUploading ? null : _sendMessage,
                        ),
                      ),
                    ],
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
}
