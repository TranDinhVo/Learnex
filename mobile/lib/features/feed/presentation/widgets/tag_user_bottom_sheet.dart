import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/datasources/feed_remote_datasource.dart';

class TagUserBottomSheet extends StatefulWidget {
  final List<String> initialSelectedUserIds;

  const TagUserBottomSheet({
    super.key,
    this.initialSelectedUserIds = const [],
  });

  @override
  State<TagUserBottomSheet> createState() => _TagUserBottomSheetState();
}

class _TagUserBottomSheetState extends State<TagUserBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FeedRemoteDatasource _datasource = getIt<FeedRemoteDatasource>();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  
  // Map lưu ID -> user info
  final Map<String, Map<String, dynamic>> _selectedUsersMap = {};

  @override
  void initState() {
    super.initState();
    // Khởi tạo danh sách mặc định
    _onSearchChanged('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() => _isLoading = true);
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _datasource.searchUsers(query.trim(), friendsOnly: true);
        if (mounted) {
          final authState = context.read<AuthBloc>().state;
          final currentUserId = authState is Authenticated ? authState.user.id : '';
          
          setState(() {
            _searchResults = results.where((u) => u['id'].toString() != currentUserId).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  void _toggleUser(Map<String, dynamic> user) {
    final id = user['id'].toString();
    setState(() {
      if (_selectedUsersMap.containsKey(id)) {
        _selectedUsersMap.remove(id);
      } else {
        _selectedUsersMap[id] = user;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 48), // balance space
                const Expanded(
                  child: Text(
                    'Tag bạn bè',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Trả về danh sách user objects
                    Navigator.of(context).pop(_selectedUsersMap.values.toList());
                  },
                  child: Text(
                    'Xong',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Search Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tên người dùng...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Selected Tags Preview
          if (_selectedUsersMap.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _selectedUsersMap.values.map((user) {
                    final name = user['full_name'] ?? user['username'] ?? 'User';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        onDeleted: () => _toggleUser(user),
                        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        deleteIconColor: theme.colorScheme.primary,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          if (_selectedUsersMap.isNotEmpty)
            const Divider(height: 1),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? const Center(child: Text('Không tìm thấy người dùng nào'))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final id = user['id'].toString();
                          final isSelected = _selectedUsersMap.containsKey(id);
                          final name = user['full_name'] ?? user['username'] ?? 'User';
                          final username = user['username'] ?? '';
                          final avatarUrl = user['avatar_url'] as String?;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null ? Text(name.isNotEmpty ? name[0] : 'U') : null,
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('@$username'),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                                : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            onTap: () => _toggleUser(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
