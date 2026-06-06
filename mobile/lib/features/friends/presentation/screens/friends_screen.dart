import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../chat/presentation/screens/chat_detail_screen.dart';
import '../../../search/presentation/screens/global_search_screen.dart';
import '../bloc/friend_bloc.dart';
import '../bloc/friend_event.dart';
import '../bloc/friend_state.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FriendBloc _bloc;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _suggestions = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  final Set<String> _pendingRequestSent = {};
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bloc = getIt<FriendBloc>();
    _bloc.add(LoadFriendsEvent());
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        _bloc.add(LoadFriendsEvent());
        break;
      case 1:
        _bloc.add(LoadFriendRequestsEvent());
        break;
      case 2:
        _bloc.add(LoadSuggestionsEvent());
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length > 2 ? 2 : parts[0].length).toUpperCase();
    }
    return '?';
  }

  Color _avatarColor(String name) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary, colorScheme.secondary, colorScheme.tertiary,
      Colors.orange, Colors.blue, Colors.purple, Colors.teal,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _goToProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _avatar(String name, String? avatarUrl, {double radius = 28}) {
    final color = _avatarColor(name);
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 2),
            color: color,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.transparent,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            onBackgroundImageError: (avatarUrl != null && avatarUrl.isNotEmpty) ? (_, __) {} : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    _initials(name),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.55),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981), // Emerald (online status for UI simulation)
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ── BLoC Listener ─────────────────────────────────────────────────────────
  void _onState(BuildContext context, FriendState state) {
    if (state is FriendActionSuccess) {
      _showSnack(state.message);
      setState(() => _processingIds.clear());
    } else if (state is FriendError) {
      _showSnack(state.message, isError: true);
      setState(() => _processingIds.clear());
    } else if (state is FriendsLoaded) {
      setState(() => _friends = state.friends);
    } else if (state is FriendRequestsLoaded) {
      setState(() => _requests = state.requests);
    } else if (state is FriendSuggestionsLoaded) {
      setState(() => _suggestions = state.suggestions);
    } else if (state is UserSearchResults) {
      setState(() => _searchResults = state.users);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<FriendBloc, FriendState>(
        listener: _onState,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface, // bg-background / bg-surface
          appBar: _buildAppBar(theme),
          body: Column(
            children: [
              _buildSegments(theme),
              if (_isSearching)
                _buildSearchBar(theme),
              Expanded(
                child: _isSearching
                    ? _buildSearchTab()
                    : TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(), // Using segment control instead of swipe
                        children: [
                          _buildFriendsTab(theme),
                          _buildRequestsTab(theme),
                          _buildSuggestionsTab(theme),
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: theme.colorScheme.primary,
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
                _searchResults.clear();
              }
            },
            child: Icon(_isSearching ? Icons.close : Icons.person_add, color: theme.colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          ),
        ),
      ),
      title: Text(
        'Bạn bè',
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: theme.colorScheme.primary,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Segments (Custom TabBar) ──────────────────────────────────────────────
  Widget _buildSegments(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow, // Use mapped color
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _segmentButton(0, 'Bạn bè', theme),
            _segmentButton(1, 'Lời mời', theme, badgeCount: _requests.length),
            _segmentButton(2, 'Gợi ý', theme),
          ],
        ),
      ),
    );
  }

  Widget _segmentButton(int index, String text, ThemeData theme, {int badgeCount = 0}) {
    final isSelected = _tabController.index == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.index = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    border: Border.all(color: theme.colorScheme.surfaceContainerLow, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          final query = val.trim();
          if (query.isEmpty) {
            setState(() { _searchResults = []; });
          } else {
            _bloc.add(SearchUsersEvent(query: query));
          }
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm người dùng...',
          hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  // ── Filter Title ─────────────────────────────────────────────────────────
  Widget _buildFilterTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0, // tracking-widest
              color: theme.colorScheme.outline,
            ),
          ),
          Row(
            children: [
              Icon(Icons.filter_list, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Lọc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB: Search Results
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSearchTab() {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (ctx, state) {
        if (state is FriendLoading) return _loadingWidget();
        if (_searchResults.isEmpty) {
          return _emptyWidget(Icons.person_search_outlined, 'Vui lòng nhập tên người dùng để tìm kiếm');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildSearchCard(_searchResults[i], Theme.of(context)),
        );
      },
    );
  }

  Widget _buildSearchCard(Map<String, dynamic> user, ThemeData theme) {
    final userId = user['id'] as String? ?? '';
    final name = user['full_name'] as String? ?? 'Người dùng';
    final username = user['username'] as String? ?? '';
    final school = user['school'] as String?;
    final avatarUrl = user['avatar_url'] as String?;
    final isPending = _pendingRequestSent.contains(userId);
    final isProcessing = _processingIds.contains(userId);

    return _buildBentoCard(
      theme: theme,
      avatar: _avatar(name, avatarUrl),
      name: name,
      school: school,
      major: '@$username',
      onTap: () => _goToProfile(userId),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isPending
              ? _outlineIconBtn(
                  icon: Icons.check,
                  color: theme.colorScheme.outline,
                  isLoading: isProcessing,
                  onTap: () {
                    setState(() { _processingIds.add(userId); _pendingRequestSent.remove(userId); });
                    _bloc.add(CancelFriendRequestEvent(userId: userId));
                  },
                )
              : _filledIconBtn(
                  icon: Icons.person_add,
                  color: theme.colorScheme.primary,
                  onColor: theme.colorScheme.onPrimary,
                  isLoading: isProcessing,
                  onTap: () {
                    setState(() { _processingIds.add(userId); _pendingRequestSent.add(userId); });
                    _bloc.add(SendFriendRequestEvent(userId: userId));
                  },
                ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 0: Friends List
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFriendsTab(ThemeData theme) {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (ctx, state) {
        if (state is FriendLoading && _friends.isEmpty) return _loadingWidget();
        if (_friends.isEmpty) {
          return _emptyWidget(
            Icons.people_outline,
            'Bạn chưa có bạn bè nào\nHãy tìm kiếm hoặc xem gợi ý!',
            actionLabel: 'Xem gợi ý kết bạn',
            onAction: () => setState(() => _tabController.index = 2),
            theme: theme,
          );
        }
        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async => _bloc.add(LoadFriendsEvent()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterTitle('Tất cả bạn bè (${_friends.length})', theme),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Padding footer for FAB
                  itemCount: _friends.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildFriendCard(_friends[i], theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> user, ThemeData theme) {
    final userId = user['id'] as String? ?? '';
    final name = user['full_name'] as String? ?? 'Người dùng';
    final school = user['school'] as String?;
    final major = user['major'] as String?;
    final avatarUrl = user['avatar_url'] as String?;

    return _buildBentoCard(
      theme: theme,
      avatar: _avatar(name, avatarUrl),
      name: name,
      school: school,
      major: major,
      onTap: () => _goToProfile(userId),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filledIconBtn(
            icon: Icons.chat, 
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
            onColor: theme.colorScheme.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    conversationId: userId,
                    partnerName: name,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.outline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: theme.colorScheme.surface,
            onSelected: (val) {
              if (val == 'unfriend') _confirmUnfriend(user);
              if (val == 'profile') _goToProfile(userId);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(children: [Icon(Icons.person_outline, size: 18), SizedBox(width: 8), Text('Xem trang cá nhân')]),
              ),
              PopupMenuItem(
                value: 'unfriend',
                child: Row(children: [Icon(Icons.person_remove_outlined, size: 18, color: Colors.red.shade400), const SizedBox(width: 8), Text('Huỷ kết bạn', style: TextStyle(color: Colors.red.shade400))]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmUnfriend(Map<String, dynamic> user) {
    final name = user['full_name'] as String? ?? 'người dùng này';
    final userId = user['id'] as String? ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Huỷ kết bạn?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn huỷ kết bạn với $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Không', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error, 
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _processingIds.add(userId));
              _bloc.add(UnfriendEvent(userId: userId));
            },
            child: const Text('Huỷ kết bạn'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: Friend Requests
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRequestsTab(ThemeData theme) {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (ctx, state) {
        if (state is FriendLoading && _requests.isEmpty) return _loadingWidget();
        if (_requests.isEmpty) {
          return _emptyWidget(Icons.mark_email_read_outlined, 'Không có lời mời kết bạn nào', theme: theme);
        }
        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async => _bloc.add(LoadFriendRequestsEvent()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterTitle('Lời mời đang chờ (${_requests.length})', theme),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildRequestCard(_requests[i], theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, ThemeData theme) {
    final requestId = req['id'] as String? ?? '';
    final requesterId = req['requester_id'] as String? ?? '';
    final name = req['requester_name'] as String? ?? 'Người dùng';
    final username = req['requester_username'] as String? ?? '';
    final avatarUrl = req['requester_avatar'] as String?;
    final isProcessing = _processingIds.contains(requestId);

    return _buildBentoCard(
      theme: theme,
      avatar: _avatar(name, avatarUrl),
      name: name,
      school: null,
      major: '@$username',
      onTap: () => requesterId.isNotEmpty ? _goToProfile(requesterId) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filledIconBtn(
            icon: Icons.check, 
            color: theme.colorScheme.primary,
            onColor: theme.colorScheme.onPrimary,
            isLoading: isProcessing,
            onTap: () {
              setState(() => _processingIds.add(requestId));
              _bloc.add(AcceptFriendRequestEvent(requestId: requestId));
            },
          ),
          const SizedBox(width: 8),
          _outlineIconBtn(
            icon: Icons.close, 
            color: theme.colorScheme.error,
            isLoading: isProcessing,
            onTap: () {
              setState(() => _processingIds.add(requestId));
              _bloc.add(RejectFriendRequestEvent(requestId: requestId));
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: Suggestions
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSuggestionsTab(ThemeData theme) {
    return BlocBuilder<FriendBloc, FriendState>(
      builder: (ctx, state) {
        if (state is FriendLoading && _suggestions.isEmpty) return _loadingWidget();
        if (_suggestions.isEmpty) {
          return _emptyWidget(
            Icons.person_search_outlined,
            'Không có gợi ý kết bạn\nHãy hoàn thiện hồ sơ của bạn!',
            theme: theme,
          );
        }
        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async => _bloc.add(LoadSuggestionsEvent()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterTitle('Được đề xuất cho bạn (${_suggestions.length})', theme),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildSuggestionCard(_suggestions[i], theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> user, ThemeData theme) {
    final userId = user['id'] as String? ?? '';
    final name = user['full_name'] as String? ?? 'Người dùng';
    final school = user['school'] as String?;
    final major = user['major'] as String?;
    final avatarUrl = user['avatar_url'] as String?;
    final isPending = _pendingRequestSent.contains(userId);
    final isProcessing = _processingIds.contains(userId);

    return _buildBentoCard(
      theme: theme,
      avatar: _avatar(name, avatarUrl),
      name: name,
      school: school,
      major: major,
      onTap: () => _goToProfile(userId),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isPending
              ? _outlineIconBtn(
                  icon: Icons.check, 
                  color: theme.colorScheme.outline,
                  isLoading: isProcessing,
                  onTap: () {
                    setState(() { _processingIds.add(userId); _pendingRequestSent.remove(userId); });
                    _bloc.add(CancelFriendRequestEvent(userId: userId));
                  },
                )
              : _filledIconBtn(
                  icon: Icons.person_add, 
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  onColor: theme.colorScheme.primary,
                  isLoading: isProcessing,
                  onTap: () {
                    setState(() { _processingIds.add(userId); _pendingRequestSent.add(userId); });
                    _bloc.add(SendFriendRequestEvent(userId: userId));
                  },
                ),
          const SizedBox(width: 4),
          _outlineIconBtn(
            icon: Icons.close, 
            color: theme.colorScheme.outline,
            onTap: () => setState(() => _suggestions.removeWhere((s) => s['id'] == userId)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shared Bento Card Design (Reflecting HTML from file_UI)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBentoCard({
    required ThemeData theme,
    required Widget avatar,
    required String name,
    required String? school,
    required String? major,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest, // Usually Colors.white within this theme
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.04), // shadow-[0_4px_20px_rgba(53,37,205,0.04)]
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600, 
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (school != null || major != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (school != null && school.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  school.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSecondaryContainer,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (major != null && major.isNotEmpty)
                              Expanded(
                                child: Text(
                                  major,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────
  Widget _filledIconBtn({
    required IconData icon,
    required Color color,
    required Color onColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      splashColor: color.withValues(alpha: 0.5),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: onColor))
            : Icon(icon, size: 18, color: onColor),
      ),
    );
  }

  Widget _outlineIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      splashColor: color.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: isLoading
            ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ── Empty / Loading ───────────────────────────────────────────────────────
  Widget _loadingWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
    ),
  );

  Widget _emptyWidget(IconData icon, String msg, {String? actionLabel, VoidCallback? onAction, ThemeData? theme}) {
    final t = theme ?? Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: t.colorScheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 52, color: t.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: t.colorScheme.onSurfaceVariant, height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.colorScheme.primary,
                  foregroundColor: t.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
