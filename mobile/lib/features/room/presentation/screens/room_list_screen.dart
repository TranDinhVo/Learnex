import 'package:flutter/material.dart';
import '../widgets/my_room_card.dart';
import '../widgets/room_list_card.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['Tất cả', 'Đang hoạt động', 'Của tôi', 'Đã tham gia'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.primary),
          onPressed: () {},
        ),
        title: Text(
          'Phòng học',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primaryContainer, width: 2),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: const Icon(Icons.person, size: 20),
            ),
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
                // Search & Filter Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm phòng học...',
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
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_filters.length, (index) {
                            final isSelected = _selectedFilterIndex == index;
                            final showDot = index == 1;
                            return Padding(
                              padding: EdgeInsets.only(right: index < _filters.length - 1 ? 8 : 0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilterIndex = index;
                                  });
                                },
                                child: _buildFilterChip(
                                  _filters[index],
                                  isSelected: isSelected,
                                  showDot: showDot,
                                  dotColor: Colors.green.shade500,
                                  theme: theme,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                // My Rooms Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phòng của bạn',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      MyRoomCard(
                        title: 'Lập trình Web',
                        shortName: 'WEB',
                        baseColor: Colors.indigo.shade600,
                        isLive: true,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      MyRoomCard(
                        title: 'Trí tuệ nhân tạo',
                        shortName: 'AI',
                        baseColor: Colors.amber.shade700,
                        isLive: false,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      MyRoomCard(
                        title: 'UI/UX Design',
                        shortName: 'UX',
                        baseColor: Colors.red.shade600,
                        isLive: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // All Rooms Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Tất cả phòng',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      RoomListCard(
                        title: 'Lập trình Web',
                        subtitle: 'React + Node.js · ôn tập nhóm',
                        shortName: 'WEB',
                        baseColor: theme.colorScheme.primary,
                        memberCount: 8,
                        tag: 'CNPM',
                        isLive: true,
                        actionText: 'Mở',
                        actionIsPrimary: false,
                        onAction: () {},
                      ),
                      const SizedBox(height: 16),
                      RoomListCard(
                        title: 'Giải tích 2 - Nhóm B',
                        subtitle: 'Giải bài tập chương 4: Đạo hàm',
                        shortName: 'GT2',
                        baseColor: Colors.indigo.shade600,
                        memberCount: 12,
                        actionText: 'Vào',
                        actionIsPrimary: true,
                        onAction: () {},
                      ),
                      const SizedBox(height: 16),
                      RoomListCard(
                        title: 'Kiến trúc máy tính',
                        subtitle: 'Tìm hiểu về tập lệnh MIPS',
                        shortName: 'KTR',
                        baseColor: Colors.blueGrey.shade600,
                        memberCount: 6,
                        actionText: 'Vào',
                        actionIsPrimary: true,
                        onAction: () {},
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
              currentIndex: 4,
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
              onChatTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
              onMeetingTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false, bool showDot = false, Color? dotColor, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(24),
        border: isSelected ? null : Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
