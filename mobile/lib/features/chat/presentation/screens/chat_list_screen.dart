import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/online_friend_avatar.dart';
import '../widgets/chat_tile.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../../friends/presentation/bloc/friend_bloc.dart';
import '../../../friends/presentation/bloc/friend_event.dart';
import '../../../friends/presentation/bloc/friend_state.dart';
import 'chat_detail_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';
import '../../../room/presentation/screens/room_list_screen.dart';
import '../../../friends/presentation/screens/friends_screen.dart';
import '../../../search/presentation/screens/global_search_screen.dart';
import 'package:learnex/shared/widgets/user_account_icon.dart';
import 'package:learnex/shared/widgets/notification_bell.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Tải danh sách bạn bè và hội thoại thực tế
    context.read<FriendBloc>().add(LoadFriendsEvent());
    context.read<ChatBloc>().add(LoadConversationsEvent());
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                elevation: 0,
                pinned: true,
                title: Row(
                  children: [
                    Icon(Icons.school, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Learnex',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.people_outline, color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Bạn bè',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FriendsScreen()),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                      );
                    },
                  ),
                  NotificationBell(iconColor: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                ],
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Tin nhắn',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF312E81), // indigo-900
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(color: theme.colorScheme.outline),
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.outline),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: BlocBuilder<FriendBloc, FriendState>(
                  builder: (context, friendState) {
                    List<dynamic> friendsList = [];
                    if (friendState is FriendsLoaded) {
                      friendsList = friendState.friends;
                    }

                    if (friendsList.isEmpty && friendState is! FriendLoading) {
                      return const SizedBox();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'ĐANG ONLINE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        friendState is FriendLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: friendsList.map((f) {
                                    final name = f['full_name'] ?? 'Học viên';
                                    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'H';
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          final friendId = f['id']?.toString();
                                          if (friendId != null) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => ChatDetailScreen(
                                                  conversationId: friendId,
                                                  partnerName: name,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: OnlineFriendAvatar(
                                          initials: initials,
                                          name: name,
                                          backgroundColor: Colors.indigo.shade600,
                                          textColor: Colors.white,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),

              // Conversation List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0).copyWith(bottom: 120),
                sliver: SliverToBoxAdapter(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, chatState) {
                      List<dynamic> conversations = [];
                      List<String> onlineUserIds = [];
                      final isLoading = chatState is ChatLoading;
                      final errorMsg = chatState is ChatError ? chatState.message : null;

                      if (chatState is ConversationsLoaded) {
                        conversations = chatState.conversations;
                        onlineUserIds = chatState.onlineUserIds;
                      }

                      if (isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (errorMsg != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Text('Lỗi: $errorMsg', style: const TextStyle(color: Colors.red)),
                          ),
                        );
                      }

                      if (conversations.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              'Chưa có cuộc hội thoại nào.',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: conversations.map((c) {
                          final otherUser = c['other_user'] ?? {};
                          final name = otherUser['full_name'] ?? 'Người dùng';
                          final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                          final lastMsgData = c['last_message'] as Map<String, dynamic>?;
                          String lastMsg = lastMsgData?['content'] ?? 'Tệp tin đính kèm';
                          
                          if (lastMsg.startsWith('[CALL_HISTORY]:')) {
                            final parts = lastMsg.split(':');
                            final type = parts.length > 1 ? parts[1] : 'VOICE';
                            final isVideo = type == 'VIDEO';
                            lastMsg = isVideo ? '📞 Cuộc gọi video' : '📞 Cuộc gọi thoại';
                          }

                          final String? createdAt = lastMsgData?['created_at']?.toString();
                          final unreadCount = c['unread_count'] ?? 0;

                          String displayTime = 'Vừa xong';
                          if (createdAt != null) {
                            try {
                              final dateTime = DateTime.parse(createdAt).toLocal();
                              final min = dateTime.minute.toString().padLeft(2, '0');
                              final period = dateTime.hour >= 12 ? 'CH' : 'SA';
                              final displayHour = dateTime.hour > 12 
                                  ? dateTime.hour - 12 
                                  : (dateTime.hour == 0 ? 12 : dateTime.hour);
                              displayTime = '$displayHour:$min $period';
                            } catch (_) {}
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: ChatTile(
                              name: name,
                              initials: initials,
                              time: displayTime,
                              lastMessage: lastMsg,
                              isUnread: unreadCount > 0,
                              unreadCount: unreadCount,
                              avatarColor: Colors.indigo.shade600,
                              avatarTextColor: Colors.white,
                              isOnline: onlineUserIds.contains(otherUser['id']?.toString()),
                              onTap: () {
                                final otherUserId = otherUser['id']?.toString() ?? '';
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      conversationId: otherUserId,
                                      partnerName: name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavBar(
              currentIndex: 3,
              onHomeTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const FeedScreen()),
                );
              },
              onFolderTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const FolderOverviewScreen()),
                );
              },
              onAddTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
              onChatTap: () {},
              onMeetingTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RoomListScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
