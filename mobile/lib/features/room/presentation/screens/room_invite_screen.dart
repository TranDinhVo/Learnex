import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../bloc/room_detail_bloc.dart';
import '../bloc/room_detail_event.dart';
import '../bloc/room_detail_state.dart';
import '../../../friends/data/repositories/friend_repository_impl.dart';

class RoomInviteScreen extends StatefulWidget {
  final String roomId;

  const RoomInviteScreen({super.key, required this.roomId});

  @override
  State<RoomInviteScreen> createState() => _RoomInviteScreenState();
}

class _RoomInviteScreenState extends State<RoomInviteScreen> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final repo = getIt<FriendRepositoryImpl>();
      final result = await repo.getFriends(page: 1, limit: 100);
      if (mounted) {
        setState(() {
          _friends = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải danh sách bạn bè', style: TextStyle(color: Colors.red))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mời bạn bè', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: BlocConsumer<RoomDetailBloc, RoomDetailState>(
        listener: (context, state) {
          if (state is RoomDetailOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is RoomDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.red))));
          }
        },
        buildWhen: (p, c) => c is MembersLoaded || c is RoomDetailLoading,
        builder: (context, state) {
          final members = context.read<RoomDetailBloc>().currentMembers;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_friends.isEmpty) {
            return const Center(child: Text('Bạn chưa có bạn bè nào để mời.'));
          }

          return ListView.builder(
            itemCount: _friends.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final friend = _friends[index];
              final friendId = friend['id'] as String;
              final name = friend['full_name'] as String? ?? friend['username'] as String? ?? 'Bạn bè';
              final avatarUrl = friend['avatar_url'] as String?;
              
              final isAlreadyMember = members.any((m) => m.userId == friendId);

              return ListTile(
                leading: CustomAvatar(
                  imageUrl: avatarUrl,
                  name: name,
                  radius: 20,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: isAlreadyMember
                    ? const Text(
                        'Đã tham gia',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          context.read<RoomDetailBloc>().add(
                            InviteMemberEvent(roomId: widget.roomId, userId: friendId)
                          );
                        },
                        child: const Text('Thêm'),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
