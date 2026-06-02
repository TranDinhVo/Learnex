import 'package:flutter/material.dart';
import '../../../../app/di.dart';
import '../../domain/room_repository.dart';

class RoomRequestsScreen extends StatefulWidget {
  final String roomId;

  const RoomRequestsScreen({super.key, required this.roomId});

  @override
  State<RoomRequestsScreen> createState() => _RoomRequestsScreenState();
}

class _RoomRequestsScreenState extends State<RoomRequestsScreen> {
  final RoomRepository _repository = getIt<RoomRepository>();
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final reqs = await _repository.getJoinRequests(widget.roomId);
      setState(() {
        _requests = reqs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tải yêu cầu tham gia', style: TextStyle(color: Colors.red))));
      }
    }
  }

  Future<void> _approveRequest(String userId) async {
    try {
      await _repository.approveJoinRequest(widget.roomId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã phê duyệt')));
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra', style: TextStyle(color: Colors.red))));
    }
  }

  Future<void> _rejectRequest(String userId) async {
    try {
      await _repository.rejectJoinRequest(widget.roomId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã từ chối')));
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra', style: TextStyle(color: Colors.red))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Yêu cầu tham gia', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('Không có yêu cầu nào', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (req['avatar_url'] != null && req['avatar_url'].toString().isNotEmpty) ? NetworkImage(req['avatar_url']) : null,
                          child: (req['avatar_url'] == null || req['avatar_url'].toString().isEmpty) ? const Icon(Icons.person) : null,
                        ),
                        title: Text(req['full_name'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('@${req['username'] ?? 'username'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _approveRequest(req['user_id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _rejectRequest(req['user_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
