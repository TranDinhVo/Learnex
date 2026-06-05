import 'package:flutter/material.dart';
import '../../../../app/di.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../friends/data/repositories/friend_repository_impl.dart';
import '../../../feed/data/repositories/feed_repository_impl.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/presentation/screens/post_detail_screen.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/image_parser.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authRepository = getIt<AuthRepositoryImpl>();
  final _friendRepository = getIt<FriendRepositoryImpl>();

  User? _user;
  Map<String, dynamic>? _friendship;
  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _authRepository.getUserById(widget.userId);
      final friendshipResponse = await _friendRepository.getFriendshipStatus(widget.userId);
      final friendship = friendshipResponse['data'] ?? friendshipResponse;

      // Load public posts of this user
      final postsResponse = await getIt<FeedRepositoryImpl>().getFeed(page: 1, limit: 10, userId: widget.userId);
      final posts = postsResponse['data'] as List<dynamic>? ?? [];

      setState(() {
        _user = user;
        _friendship = friendship;
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải thông tin trang cá nhân.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLikePost(String postId) async {
    try {
      setState(() {
        _posts = _posts.map((post) {
          if (post['id'].toString() == postId) {
            final isCurrentlyLiked = post['is_liked'] == true;
            final currentLikeCount = post['like_count'] as int? ?? 0;
            return {
              ...post,
              'is_liked': !isCurrentlyLiked,
              'like_count': isCurrentlyLiked
                  ? (currentLikeCount > 0 ? currentLikeCount - 1 : 0)
                  : currentLikeCount + 1,
            };
          }
          return post;
        }).toList();
      });

      await getIt<FeedRepositoryImpl>().toggleLike(postId);
    } catch (_) {}
  }

  Future<void> _toggleSavePost(String postId) async {
    try {
      setState(() {
        _posts = _posts.map((post) {
          if (post['id'].toString() == postId) {
            final isCurrentlySaved = post['is_saved'] == true;
            return {
              ...post,
              'is_saved': !isCurrentlySaved,
            };
          }
          return post;
        }).toList();
      });

      await getIt<FeedRepositoryImpl>().toggleSave(postId);
    } catch (_) {}
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _actionLoading = true);
    try {
      final res = await _friendRepository.sendRequest(widget.userId);
      setState(() {
        _friendship = {
          'status': 'pending',
          'is_requester': true,
          'id': res['id'] ?? res['data']?['id'],
        };
        _actionLoading = false;
      });
      _showSnackBar('Đã gửi lời mời kết bạn!');
    } catch (e) {
      setState(() => _actionLoading = false);
      _showSnackBar('Gửi lời mời thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    setState(() => _actionLoading = true);
    try {
      await _friendRepository.acceptRequest(requestId);
      setState(() {
        _friendship = {
          'status': 'accepted',
          'is_requester': false,
          'id': requestId,
        };
        _actionLoading = false;
      });
      _showSnackBar('Hai bạn đã trở thành bạn bè!');
    } catch (e) {
      setState(() => _actionLoading = false);
      _showSnackBar('Chấp nhận kết bạn thất bại.');
    }
  }

  Future<void> _rejectFriendRequest(String requestId) async {
    setState(() => _actionLoading = true);
    try {
      await _friendRepository.rejectRequest(requestId);
      setState(() {
        _friendship = {'status': 'none'};
        _actionLoading = false;
      });
      _showSnackBar('Đã từ chối lời mời kết bạn.');
    } catch (e) {
      setState(() => _actionLoading = false);
      _showSnackBar('Từ chối thất bại.');
    }
  }

  Future<void> _unfriend() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy kết bạn', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn hủy kết bạn với ${_user?.fullName ?? 'người này'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hủy kết bạn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      await _friendRepository.unfriend(widget.userId);
      setState(() {
        _friendship = {'status': 'none'};
        _actionLoading = false;
      });
      _showSnackBar('Đã hủy kết bạn.');
    } catch (e) {
      setState(() => _actionLoading = false);
      _showSnackBar('Hủy kết bạn thất bại.');
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

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
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurfaceVariant, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Trang cá nhân',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text('Không tìm thấy người dùng.'));
    }

    final initials = _user!.fullName.isNotEmpty ? _user!.fullName[0].toUpperCase() : 'U';

    return CustomScrollView(
      slivers: [
        // Profile Details Header
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name & Verified status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _user!.fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.verified, color: theme.colorScheme.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 2),

                // Username
                Text(
                  '@${_user!.username}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),

                // School & Major info
                if ((_user!.school ?? '').isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_user!.school} · ${_user!.major ?? "Học viên"}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Bio
                Text(
                  _user!.bio ?? 'Chào mừng bạn đến với trang cá nhân của tôi!',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Friend Interactive Actions
                _buildFriendActionButton(theme),
              ],
            ),
          ),
        ),

        // Stats summary row
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(_user!.postsCount.toString(), 'Bài đăng', theme),
                _buildStatItem(_user!.friendsCount.toString(), 'Bạn bè', theme),
                _buildStatItem(_user!.documentsCount.toString(), 'Tài liệu', theme),
              ],
            ),
          ),
        ),

        // Section Header: Bài đăng
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 24.0, bottom: 8.0),
            child: Text(
              'Bài đăng',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // List of Posts or Empty state
        if (_posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.feed_outlined, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có bài đăng nào công khai.',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];
                  final name = post['author_name'] ?? _user?.fullName ?? 'Học viên';
                  final handle = post['author_username'] != null ? '@${post['author_username']}' : '@student';
                  final content = post['content'] ?? '';

                  final imageUrls = ImageParser.parseImageUrls(post['image_urls']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: PostCard(
                      authorName: name,
                      authorHandle: handle,
                      timeAgo: formatTimeAgo(post['created_at']?.toString()),
                      authorInitials: name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      authorAvatarUrl: post['author_avatar'] as String?,
                      avatarColor: Colors.indigo.shade100,
                      avatarTextColor: Colors.indigo.shade700,
                      content: content,
                      location: post['location'] as String?,
                      postType: imageUrls.isNotEmpty
                          ? PostType.image
                          : (post['document_id'] != null ? PostType.document : PostType.text),
                      imageUrls: imageUrls,
                      documentName: post['document_title'] as String? ?? 'Tài liệu',
                      documentSize: post['document_size'] != null
                          ? '${((post['document_size'] as num) / 1024).toStringAsFixed(0)} KB'
                          : null,
                      documentUrl: post['document_url'] as String?,
                      taggedUsers: post['tagged_users'] as List<dynamic>?,
                      visibility: post['visibility']?.toString(),
                      likes: post['like_count'] ?? 0,
                      comments: post['comment_count'] ?? 0,
                      isLiked: post['is_liked'] == true,
                      isSaved: post['is_saved'] == true,
                      onLikeTap: () => _toggleLikePost(post['id'].toString()),
                      onSaveTap: () => _toggleSavePost(post['id'].toString()),
                      onCommentTap: () async {
                        final updated = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post),
                          ),
                        );
                        if (updated != null && mounted) {
                          setState(() {
                            _posts = _posts.map((p) {
                              if (p['id'].toString() == updated['id'].toString()) {
                                return updated;
                              }
                              return p;
                            }).toList();
                          });
                        }
                      },
                      onTaggedUserTap: (taggedUserId) {
                        final authState = context.read<AuthBloc>().state;
                        final currentUserId = authState is Authenticated ? authState.user.id : '';
                        if (taggedUserId == currentUserId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        } else if (taggedUserId != widget.userId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(userId: taggedUserId),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
                childCount: _posts.length,
              ),
            ),
          ),

        // Bottom Spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildFriendActionButton(ThemeData theme) {
    if (_actionLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final status = _friendship?['status'] ?? 'none';
    final isRequester = _friendship?['is_requester'] ?? false;
    final friendshipId = _friendship?['id']?.toString();

    // 1. Accepted (Friends) -> Show Red Unfriend button
    if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _unfriend,
          icon: const Icon(Icons.person_remove_outlined, size: 18),
          label: const Text('Hủy kết bạn'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    // 2. Pending (Request Sent by me) -> Show disabled Request Sent
    if (status == 'pending' && isRequester) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule_rounded, size: 18),
          label: const Text('Đã gửi yêu cầu kết bạn'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    // 3. Pending (Request Sent to me) -> Show Accept & Reject row
    if (status == 'pending' && !isRequester && friendshipId != null) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptFriendRequest(friendshipId),
              icon: const Icon(Icons.done, size: 18, color: Colors.white),
              label: const Text('Đồng ý', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectFriendRequest(friendshipId),
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              label: const Text('Từ chối', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // 4. Default: None -> Show Add Friend button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sendFriendRequest,
        icon: const Icon(Icons.person_add_outlined, size: 18, color: Colors.white),
        label: const Text('Kết bạn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
