import 'package:flutter/material.dart';
import '../widgets/online_friend_avatar.dart';
import '../widgets/chat_tile.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import 'chat_detail_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.primary),
          onPressed: () {},
        ),
        title: Text(
          'Tin nhắn',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_square, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
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

                // Online Friends Section
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OnlineFriendAvatar(
                        initials: 'AN',
                        name: 'Anh Nam',
                        backgroundColor: Colors.indigo.shade600,
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      OnlineFriendAvatar(
                        initials: 'TL',
                        name: 'Thảo Ly',
                        backgroundColor: Colors.red.shade500,
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      OnlineFriendAvatar(
                        initials: 'TK',
                        name: 'Trọng Khải',
                        backgroundColor: Colors.green.shade600,
                        textColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      OnlineFriendAvatar(
                        initials: 'HM',
                        name: 'Hoài My',
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        textColor: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 16),
                      OnlineFriendAvatar(
                        initials: 'QD',
                        name: 'Quốc Duy',
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        textColor: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Conversation List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      ChatTile(
                        name: 'Anh Nam',
                        initials: 'AN',
                        time: '2 phút',
                        lastMessage: 'Bạn có tài liệu CNPM không?',
                        isUnread: true,
                        unreadCount: 2,
                        avatarColor: Colors.indigo.shade600,
                        avatarTextColor: Colors.white,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChatDetailScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      ChatTile(
                        name: 'Thảo Ly',
                        initials: 'TL',
                        time: '1 giờ',
                        lastMessage: 'Bạn: OK mình sẽ gửi sau nhé',
                        avatarColor: Colors.red.shade500,
                        avatarTextColor: Colors.white,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChatDetailScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      ChatTile(
                        name: 'Hoài My',
                        initials: 'HM',
                        time: 'hôm qua',
                        lastMessage: 'Cảm ơn bạn nhiều lắm!',
                        avatarColor: theme.colorScheme.surfaceContainerHighest,
                        avatarTextColor: theme.colorScheme.outlineVariant,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChatDetailScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      ChatTile(
                        name: 'Trọng Khải',
                        initials: 'TK',
                        time: '2 ngày trước',
                        lastMessage: 'Tuần sau có đi học không ông?',
                        avatarColor: Colors.indigo.shade100,
                        avatarTextColor: Colors.indigo.shade600,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChatDetailScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
              onAddTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
              },
              onChatTap: () {},
              onMeetingTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng Meeting đang được phát triển.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
