import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

class FriendPickerBottomSheet extends StatefulWidget {
  final List<String> initiallyExcludedUserIds;

  const FriendPickerBottomSheet({
    super.key,
    required this.initiallyExcludedUserIds,
  });

  static Future<List<String>?> show(BuildContext context, List<String> initial) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FriendPickerBottomSheet(initiallyExcludedUserIds: initial),
    );
  }

  @override
  State<FriendPickerBottomSheet> createState() => _FriendPickerBottomSheetState();
}

class _FriendPickerBottomSheetState extends State<FriendPickerBottomSheet> {
  final Dio dio = GetIt.instance<Dio>();
  List<dynamic> _friends = [];
  bool _isLoading = true;
  String? _error;
  
  late Set<String> _excludedIds;

  @override
  void initState() {
    super.initState();
    _excludedIds = Set.from(widget.initiallyExcludedUserIds);
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final response = await dio.get('/friends');
      if (mounted) {
        setState(() {
          _friends = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách bạn bè';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn bạn bè để loại trừ',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(_excludedIds.toList());
                    },
                    child: const Text('Xong', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _friends.isEmpty
                          ? const Center(child: Text('Bạn chưa có bạn bè nào', style: TextStyle(color: Colors.white70)))
                          : ListView.builder(
                              itemCount: _friends.length,
                              itemBuilder: (context, index) {
                                final friend = _friends[index];
                                // API trả về trực tiếp user object với field full_name
                                final user = friend['friend'] ?? friend;
                                final userId = user['id'];
                                final userName = user['full_name'] as String? 
                                    ?? user['username'] as String? 
                                    ?? 'Người dùng';
                                final avatarUrl = user['avatar_url'] as String? 
                                    ?? user['avatarUrl'] as String?;
                                
                                final isExcluded = _excludedIds.contains(userId);

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                    child: avatarUrl == null ? const Icon(Icons.person) : null,
                                  ),
                                  title: Text(userName, style: const TextStyle(color: Colors.white)),
                                  trailing: Icon(
                                    isExcluded ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isExcluded ? Colors.red : Colors.white54,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (isExcluded) {
                                        _excludedIds.remove(userId);
                                      } else {
                                        _excludedIds.add(userId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
