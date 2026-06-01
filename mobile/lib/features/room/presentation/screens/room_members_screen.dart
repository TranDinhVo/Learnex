import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../bloc/room_detail_bloc.dart';
import '../bloc/room_detail_event.dart';
import '../bloc/room_detail_state.dart';
import '../../data/models/room_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class RoomMembersScreen extends StatefulWidget {
  final String roomId;
  final String myRole;
  final String ownerId;

  const RoomMembersScreen({
    super.key,
    required this.roomId,
    required this.myRole,
    required this.ownerId,
  });

  @override
  State<RoomMembersScreen> createState() => _RoomMembersScreenState();
}

class _RoomMembersScreenState extends State<RoomMembersScreen> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
    }
  }

  void _showMemberMenu(BuildContext context, RoomMemberModel member) {
    // Không thao tác lên chính mình
    if (member.userId == _currentUserId) return;

    // Không ai được thao tác lên Chủ phòng (Trừ khi sau này có tính năng chuyển nhượng)
    if (member.userId == widget.ownerId) return;

    // Moderator không thể thao tác lên Moderator khác
    if (widget.myRole == 'moderator' && member.role == 'moderator') return;

    final bloc = context.read<RoomDetailBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              
              if (widget.myRole == 'owner') ...[
                if (member.role == 'member')
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.green),
                    title: const Text('Thăng cấp Quản trị viên'),
                    onTap: () {
                      Navigator.pop(ctx);
                      bloc.add(UpdateMemberRoleEvent(roomId: widget.roomId, userId: member.userId, role: 'moderator'));
                    },
                  ),
                if (member.role == 'moderator')
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.orange),
                    title: const Text('Hạ quyền xuống Thành viên'),
                    onTap: () {
                      Navigator.pop(ctx);
                      bloc.add(UpdateMemberRoleEvent(roomId: widget.roomId, userId: member.userId, role: 'member'));
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Nhường quyền Chủ phòng'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showConfirmTransferOwnership(context, bloc, member);
                  },
                ),
              ],
              
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('Xóa khỏi phòng', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showConfirmKick(context, bloc, member);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmKick(BuildContext context, RoomDetailBloc bloc, RoomMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa ${member.fullName ?? member.username} khỏi phòng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(KickMemberEvent(roomId: widget.roomId, userId: member.userId));
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showConfirmTransferOwnership(BuildContext context, RoomDetailBloc bloc, RoomMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn nhường quyền Chủ phòng cho ${member.fullName ?? member.username}? Bạn sẽ trở thành Quản trị viên.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(TransferOwnershipEvent(roomId: widget.roomId, newOwnerId: member.userId));
            },
            child: const Text('Đồng ý', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          if (state is RoomDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = context.read<RoomDetailBloc>().currentMembers;

          if (members.isEmpty) {
            return const Center(child: Text('Không có thành viên nào'));
          }

          // Sắp xếp: Owner -> Moderator -> Member
          members.sort((a, b) {
            if (a.userId == widget.ownerId) return -1;
            if (b.userId == widget.ownerId) return 1;
            if (a.role == 'moderator' && b.role != 'moderator') return -1;
            if (b.role == 'moderator' && a.role != 'moderator') return 1;
            return 0;
          });

          return ListView.builder(
            itemCount: members.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final member = members[index];
              final isMe = member.userId == _currentUserId;
              final isOwner = member.userId == widget.ownerId;
              final isMod = member.role == 'moderator';

              return ListTile(
                leading: CustomAvatar(
                  imageUrl: member.avatarUrl,
                  name: member.fullName ?? member.username ?? 'User',
                  radius: 20,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.fullName ?? member.username ?? 'Người dùng',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('(Bạn)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                  ],
                ),
                subtitle: Text(
                  isOwner ? 'Chủ phòng' : (isMod ? 'Quản trị viên' : 'Thành viên'),
                  style: TextStyle(
                    color: isOwner ? Colors.orange.shade700 : (isMod ? Colors.green.shade700 : Colors.grey),
                    fontWeight: isOwner || isMod ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                trailing: (widget.myRole == 'owner' || widget.myRole == 'moderator') && !isOwner && !isMe
                    ? IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () => _showMemberMenu(context, member),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
