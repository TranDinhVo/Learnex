import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';
import '../widgets/my_room_card.dart';
import '../widgets/room_list_card.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../screens/room_detail_screen.dart';
import '../../data/models/room_model.dart';
import 'package:learnex/shared/widgets/user_account_icon.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Tất cả', 'Đang hoạt động', 'Của tôi', 'Đã tham gia'];
  late RoomBloc _bloc;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _bloc = getIt<RoomBloc>()..add(LoadRoomsEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    _bloc.add(LoadRoomsEvent(isRefresh: true));
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
    String privacyMode = 'public';

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
                  DropdownButtonFormField<String>(
                    initialValue: privacyMode,
                    decoration: InputDecoration(
                      labelText: 'Chế độ phòng',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Công khai (Ai cũng có thể vào)')),
                      DropdownMenuItem(value: 'private', child: Text('Riêng tư (Chỉ ai được mời)')),
                      DropdownMenuItem(value: 'approval', child: Text('Cần phê duyệt (Yêu cầu duyệt)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          privacyMode = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: theme.colorScheme.outline)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    _bloc.add(CreateRoomEvent(
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      privacyMode: privacyMode,
                    ));
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

  void _confirmDeleteRoom(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: const Text('Xóa phòng học', style: TextStyle(color: Colors.red)),
          content: Text('Bạn có chắc chắn muốn xóa phòng "${room.name}"? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: theme.colorScheme.outline)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _bloc.add(DeleteRoomEvent(roomId: room.id));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  void _showEditRoomDialog(RoomModel room) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: room.name);
    final descController = TextEditingController(text: room.description ?? '');
    String privacyMode = room.privacyMode;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Cập nhật phòng học',
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
                  DropdownButtonFormField<String>(
                    initialValue: privacyMode,
                    decoration: InputDecoration(
                      labelText: 'Chế độ phòng',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Công khai')),
                      DropdownMenuItem(value: 'private', child: Text('Riêng tư')),
                      DropdownMenuItem(value: 'approval', child: Text('Cần phê duyệt')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          privacyMode = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: theme.colorScheme.outline)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    _bloc.add(UpdateRoomEvent(
                      id: room.id,
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      privacyMode: privacyMode,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRoomOptions(RoomModel room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Chỉnh sửa thông tin phòng'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditRoomDialog(room);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa phòng'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteRoom(room);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRoomAction(RoomModel room, String? currentUserId) {
    final isOwner = room.ownerId == currentUserId;

    if (isOwner || room.isMember) {
      _enterRoom(room);
    } else {
      _bloc.add(JoinRoomEvent(roomId: room.id));
    }
  }

  void _enterRoom(RoomModel room) {
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
                  room.name,
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
              Text(room.description ?? 'Không có mô tả nào cho phòng học này.'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.groups, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('${room.memberCount} thành viên'),
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
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RoomDetailScreen(
                    roomId: room.id,
                    roomName: room.name,
                  ),
                ));
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

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state is RoomOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
          } else if (state is RoomError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                          icon: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                          tooltip: 'Tạo phòng học',
                          onPressed: _showCreateRoomDialog,
                        ),
                        const UserAccountIcon(),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
                        child: const Text(
                          'Phòng học',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Color(0xFF312E81), // indigo-900
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 100),
                      sliver: SliverToBoxAdapter(
                  child: BlocBuilder<RoomBloc, RoomState>(
                    builder: (context, state) {
                      String? currentUserId;
                      final authState = context.read<AuthBloc>().state;
                      if (authState is Authenticated) currentUserId = authState.user.id;
                      
                      List<RoomModel> rooms = [];
                      if (state is RoomsLoaded) {
                        rooms = state.rooms;
                      }
                      
                      final myRooms = rooms.where((r) => r.ownerId == currentUserId).toList();
                      
                      List<RoomModel> filteredRooms = [];
                      if (_selectedFilterIndex == 0) {
                        filteredRooms = rooms;
                      } else if (_selectedFilterIndex == 1) {
                        filteredRooms = rooms.where((r) => r.name.hashCode % 2 == 0 || r.memberCount > 1).toList();
                      } else if (_selectedFilterIndex == 2) {
                        filteredRooms = myRooms;
                      } else if (_selectedFilterIndex == 3) {
                        filteredRooms = rooms.where((r) => r.isMember).toList();
                      }
                      
                      if (_searchQuery.isNotEmpty) {
                        filteredRooms = filteredRooms.where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search & Filter
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextField(
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.trim();
                                    });
                                  },
                                  onSubmitted: (val) {
                                    _bloc.add(LoadRoomsEvent(isRefresh: true, searchQuery: val.trim()));
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
                                    child: const Text('Xem tất cả'),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (state is RoomLoading && myRooms.isEmpty)
                             const Center(child: CircularProgressIndicator())
                          else if (myRooms.isEmpty)
                             Padding(
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
                                     Icon(Icons.forum_outlined, size: 32, color: theme.colorScheme.primary),
                                     const SizedBox(height: 8),
                                     const Text(
                                       'Bạn chưa sở hữu phòng học nào.',
                                       textAlign: TextAlign.center,
                                     ),
                                     const SizedBox(height: 12),
                                     ElevatedButton.icon(
                                       onPressed: _showCreateRoomDialog,
                                       icon: const Icon(Icons.add, size: 16),
                                       label: const Text('Tạo ngay'),
                                     ),
                                   ],
                                 ),
                               ),
                             )
                          else 
                             SingleChildScrollView(
                               scrollDirection: Axis.horizontal,
                               padding: const EdgeInsets.symmetric(horizontal: 16.0),
                               child: Row(
                                 children: myRooms.map((room) {
                                   return Padding(
                                     padding: const EdgeInsets.only(right: 12.0),
                                     child: MyRoomCard(
                                       title: room.name,
                                       shortName: _getRoomShortName(room.name),
                                       baseColor: _getRoomColor(room.name),
                                       isLive: room.name.hashCode % 2 == 0,
                                       onTap: () => _handleRoomAction(room, currentUserId),
                                       onOptions: () => _showRoomOptions(room),
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
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (state is RoomLoading && filteredRooms.isEmpty)
                             const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator()))
                          else if (filteredRooms.isEmpty)
                             const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Không tìm thấy phòng nào.')))
                          else 
                             Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 16.0),
                               child: ListView.separated(
                                 shrinkWrap: true,
                                 physics: const NeverScrollableScrollPhysics(),
                                 itemCount: filteredRooms.length,
                                 separatorBuilder: (_, __) => const SizedBox(height: 16),
                                 itemBuilder: (context, index) {
                                   final room = filteredRooms[index];
                                   final isOwner = room.ownerId == currentUserId;

                                   return RoomListCard(
                                     title: room.name,
                                     subtitle: room.description ?? 'Ôn tập nhóm học tập',
                                     shortName: _getRoomShortName(room.name),
                                     baseColor: _getRoomColor(room.name),
                                     memberCount: room.memberCount,
                                     tag: room.privacyMode.toUpperCase(),
                                     isLive: room.name.hashCode % 2 == 0,
                                     actionText: isOwner ? 'Mở' : (room.isMember ? 'Vào' : (room.isPending ? 'Đang chờ duyệt' : 'Tham gia')),
                                     actionIsPrimary: !isOwner && !room.isMember && !room.isPending,
                                     onOptions: isOwner ? () => _showRoomOptions(room) : null,
                                     onAction: () {
                                       if (room.isPending) {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                           const SnackBar(content: Text('Yêu cầu của bạn đang chờ phê duyệt')),
                                         );
                                         return;
                                       }
                                       _handleRoomAction(room, currentUserId);
                                     },
                                   );
                                 },
                               ),
                             ),
                        ],
                      );
                    },
                  ),
                  ),
                ),
              ],
            ),
          ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: AppBottomNavBar(
                  currentIndex: 4,
                  onHomeTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FeedScreen())),
                  onFolderTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FolderOverviewScreen())),
                  onAddTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen())),
                  onChatTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChatListScreen())),
                  onMeetingTap: () {},
                ),
              ),
            ],
          ),
        ),
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
              width: 8, height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
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
