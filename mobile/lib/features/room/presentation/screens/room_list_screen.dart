import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
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

  List<dynamic> _rooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = getIt<Dio>();
      final response = await dio.get('/rooms');
      if (response.statusCode == 200) {
        final resData = response.data;
        final List<dynamic> list = (resData['data'] ?? resData) as List<dynamic>;
        if (mounted) {
          setState(() {
            _rooms = list;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getRoomColor(String name) {
    final colors = [
      Colors.indigo.shade600,
      Colors.amber.shade700,
      Colors.red.shade600,
      Colors.blue.shade600,
      Colors.teal.shade600,
      Colors.purple.shade600,
      Colors.green.shade600,
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  String _getRoomShortName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || name.trim().isEmpty) return 'RM';
    if (words.length == 1) {
      final w = words[0];
      return w.substring(0, w.length > 3 ? 3 : w.length).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  void _showCreateRoomDialog() {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Tạo phòng học mới',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên phòng',
                      hintText: 'Nhập tên phòng học...',
                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                      border: const UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      hintText: 'Nhập mô tả phòng học...',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phòng riêng tư (Private)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Switch(
                        value: isPrivate,
                        onChanged: (val) {
                          setDialogState(() {
                            isPrivate = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: theme.colorScheme.outline)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    try {
                      setState(() {
                        _isLoading = true;
                      });
                      final dio = getIt<Dio>();
                      await dio.post('/rooms', data: {
                        'name': nameController.text.trim(),
                        'description': descController.text.trim(),
                        'is_private': isPrivate,
                      });
                      _loadRooms();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã tạo phòng học thành công!'),
                            backgroundColor: Colors.green.shade600,
                          ),
                        );
                      }
                    } catch (e) {
                      _loadRooms();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi tạo phòng: $e'),
                            backgroundColor: Colors.red.shade600,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleRoomAction(dynamic room, String? currentUserId) async {
    final dio = getIt<Dio>();
    final roomId = room['id'];
    final isOwner = room['owner_id'] == currentUserId;

    try {
      setState(() {
        _isLoading = true;
      });

      if (isOwner) {
        _enterRoom(room);
        return;
      }

      // Call join endpoint
      await dio.post('/rooms/$roomId/join');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tham gia phòng "${room['name']}" thành công!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
      _loadRooms();
    } catch (e) {
      // If already joined, we can enter the room directly
      if (e.toString().contains('already a member')) {
        _enterRoom(room);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi tham gia phòng: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _enterRoom(dynamic room) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.meeting_room, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  room['name'],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mô tả phòng:',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 4),
              Text(room['description'] ?? 'Không có mô tả nào cho phòng học này.'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.groups, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('${room['member_count'] ?? 1} thành viên'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng', style: TextStyle(color: theme.colorScheme.outline)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng thoại / video nhóm đang được phát triển.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Vào học nhóm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get current user ID from AuthBloc
    final authState = context.read<AuthBloc>().state;
    String? currentUserId;
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    }

    // Filter my rooms (rooms owned by current user)
    final myRooms = _rooms.where((r) => r['owner_id'] == currentUserId).toList();

    // Filter rooms for list according to chosen filter chip
    List<dynamic> filteredRooms = [];
    if (_selectedFilterIndex == 0) {
      // Tất cả
      filteredRooms = _rooms;
    } else if (_selectedFilterIndex == 1) {
      // Đang hoạt động: rooms with member count > 0 or matching hash logic to simulate premium live status
      filteredRooms = _rooms.where((r) {
        final isLive = r['name'].hashCode % 2 == 0;
        return isLive || (r['member_count'] ?? 0) > 1;
      }).toList();
    } else if (_selectedFilterIndex == 2) {
      // Của tôi
      filteredRooms = myRooms;
    } else if (_selectedFilterIndex == 3) {
      // Đã tham gia (rooms you do not own, since you're automatically a member of public rooms or joined ones)
      filteredRooms = _rooms.where((r) => r['owner_id'] != currentUserId).toList();
    }

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
            onPressed: _showCreateRoomDialog,
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
          RefreshIndicator(
            onRefresh: _loadRooms,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                          onChanged: (val) {
                            // Simple client-side search filtering
                            setState(() {
                              if (val.trim().isEmpty) {
                                _loadRooms();
                              } else {
                                filteredRooms = _rooms
                                    .where((r) => r['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(val.toLowerCase()))
                                    .toList();
                              }
                            });
                          },
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
                        if (myRooms.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilterIndex = 2; // Jump to "Của tôi"
                              });
                            },
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
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : myRooms.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 32,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bạn chưa sở hữu phòng học nào.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _showCreateRoomDialog,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Tạo ngay'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: myRooms.map((room) {
                                  final name = room['name'] ?? '';
                                  final isLive = name.hashCode % 2 == 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: MyRoomCard(
                                      title: name,
                                      shortName: _getRoomShortName(name),
                                      baseColor: _getRoomColor(name),
                                      isLive: isLive,
                                      onTap: () => _handleRoomAction(room, currentUserId),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                  const SizedBox(height: 32),

                  // All Rooms Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _selectedFilterIndex == 0 ? 'Tất cả phòng' : _filters[_selectedFilterIndex],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                                child: Column(
                                  children: [
                                    const Icon(Icons.cloud_off, size: 48, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Không thể tải phòng học: $_error',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _loadRooms,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : filteredRooms.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.meeting_room_outlined, size: 48, color: theme.colorScheme.outline),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Không tìm thấy phòng nào.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme.colorScheme.outline,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredRooms.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final room = filteredRooms[index];
                                      final name = room['name'] ?? '';
                                      final desc = room['description'] ?? 'Ôn tập nhóm học tập';
                                      final count = room['member_count'] ?? 1;
                                      final isLive = name.hashCode % 2 == 0;
                                      final isOwner = room['owner_id'] == currentUserId;

                                      return RoomListCard(
                                        title: name,
                                        subtitle: desc,
                                        shortName: _getRoomShortName(name),
                                        baseColor: _getRoomColor(name),
                                        memberCount: count,
                                        tag: room['is_private'] == true ? 'PRIVATE' : 'PUBLIC',
                                        isLive: isLive,
                                        actionText: isOwner ? 'Mở' : 'Vào',
                                        actionIsPrimary: !isOwner,
                                        onAction: () => _handleRoomAction(room, currentUserId),
                                      );
                                    },
                                  ),
                                ),
                ],
              ),
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

