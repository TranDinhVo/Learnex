import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/profile_header.dart';
import 'edit_profile_screen.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../feed/presentation/screens/edit_post_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../room/presentation/screens/room_list_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../app/di.dart';
import '../../../feed/data/repositories/feed_repository_impl.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/presentation/screens/post_detail_screen.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/image_parser.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  int _selectedTabIndex = 0; // 0 for Posts, 1 for Settings
  List<dynamic> _myPosts = [];
  bool _postsLoading = false;
  String? _postsError;
  int? _localPostCount;

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        _postsLoading = true;
        _postsError = null;
      });

      try {
        final res = await getIt<FeedRepositoryImpl>().getFeed(page: 1, limit: 10, userId: authState.user.id);
        setState(() {
          _myPosts = res['data'] as List<dynamic>? ?? [];
          _postsLoading = false;
          _localPostCount = authState.user.postsCount;
        });
      } catch (e) {
        setState(() {
          _postsError = 'Không thể tải danh sách bài viết.';
          _postsLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLikePost(String postId) async {
    try {
      setState(() {
        _myPosts = _myPosts.map((post) {
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
        _myPosts = _myPosts.map((post) {
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

  Future<void> _deletePost(String postId) async {
    try {
      setState(() {
        _myPosts = _myPosts.where((post) => post['id'].toString() != postId).toList();
        if (_localPostCount != null && _localPostCount! > 0) {
          _localPostCount = _localPostCount! - 1;
        }
      });
      await getIt<FeedRepositoryImpl>().deletePost(postId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get dynamic state from AuthBloc
    final authState = context.watch<AuthBloc>().state;
    String name = 'Học viên Learnex';
    String username = 'student';
    String bio = 'Chào mừng bạn đến với Learnex!';
    String school = 'Trường học của tôi';
    String major = 'Ngành học của tôi';
    String initials = 'U';
    String friendCount = '0';
    String docCount = '0';
    String postCount = '0';

    if (authState is Authenticated) {
      final user = authState.user;
      name = user.fullName;
      username = user.username;
      bio = user.bio ?? 'Học tập cùng cộng đồng!';
      school = user.school ?? 'Chưa cập nhật trường';
      major = user.major ?? 'Chưa cập nhật ngành';
      initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
      friendCount = user.friendsCount.toString();
      docCount = user.documentsCount.toString();
      postCount = _localPostCount != null ? _localPostCount.toString() : user.postsCount.toString();
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // Khi đăng xuất, quay lại màn hình đăng nhập
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  elevation: 0,
                  pinned: true,
                  centerTitle: true,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurfaceVariant, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    'Hồ sơ cá nhân',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurfaceVariant),
                      onPressed: () {},
                    ),
                  ],
                ),
  
                // Profile Header
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    name: name,
                    username: username,
                    bio: bio,
                    school: school,
                    major: major,
                    initials: initials,
                    onEditTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                  ),
                ),
  
                // Stats Row
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 1),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(postCount, 'Bài đăng', theme),
                        _buildStatItem(friendCount, 'Bạn bè', theme),
                        _buildStatItem(docCount, 'Tài liệu', theme),
                      ],
                    ),
                  ),
                ),

                // Tab Selector
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedTabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedTabIndex == 0
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.feed_outlined,
                                        size: 18,
                                        color: _selectedTabIndex == 0
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Bài đăng',
                                        style: TextStyle(
                                          fontWeight: _selectedTabIndex == 0
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: _selectedTabIndex == 0
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedTabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _selectedTabIndex == 1
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.settings_outlined,
                                        size: 18,
                                        color: _selectedTabIndex == 1
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cài đặt',
                                        style: TextStyle(
                                          fontWeight: _selectedTabIndex == 1
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: _selectedTabIndex == 1
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                ),

                if (_selectedTabIndex == 0) ...[
                  if (_postsLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_postsError != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_postsError!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadMyPosts,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_myPosts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.feed_outlined, size: 48, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'Bạn chưa có bài đăng nào công khai.',
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = _myPosts[index];
                            final authorName = post['author_name'] ?? name;
                            final authorHandle = post['author_username'] != null ? '@${post['author_username']}' : '@$username';
                            final postContent = post['content'] ?? '';

                            final imageUrls = ImageParser.parseImageUrls(post['image_urls']);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: PostCard(
                                authorName: authorName,
                                authorHandle: authorHandle,
                                timeAgo: formatTimeAgo(post['created_at']?.toString()),
                                authorInitials: authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                                authorAvatarUrl: post['author_avatar'] as String?,
                                avatarColor: Colors.indigo.shade100,
                                avatarTextColor: Colors.indigo.shade700,
                                content: postContent,
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
                                onDeleteTap: () => _deletePost(post['id'].toString()),
                                onEditTap: () async {
                                  final updated = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EditPostScreen(post: post),
                                    ),
                                  );
                                  if (updated != null && mounted) {
                                    setState(() {
                                      _myPosts = _myPosts.map((p) {
                                        if (p['id'].toString() == updated['id'].toString()) {
                                          return updated;
                                        }
                                        return p;
                                      }).toList();
                                    });
                                  }
                                },
                                onCommentTap: () async {
                                  final updated = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PostDetailScreen(post: post),
                                    ),
                                  );
                                  if (updated != null && mounted) {
                                    setState(() {
                                      _myPosts = _myPosts.map((p) {
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
                                  if (taggedUserId != currentUserId) {
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
                          childCount: _myPosts.length,
                        ),
                      ),
                    ),
                ] else ...[
                  // Settings Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'CÀI ĐẶT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.person_outline,
                            title: 'Chỉnh sửa hồ sơ',
                            theme: theme,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: Icons.lock_outline,
                            title: 'Đổi mật khẩu',
                            theme: theme,
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildSettingsSwitch(
                            icon: Icons.dark_mode_outlined,
                            title: 'Chế độ tối',
                            value: _isDarkMode,
                            theme: theme,
                            onChanged: (val) {
                              setState(() {
                                _isDarkMode = val;
                              });
                            },
                          ),
                          _buildDivider(),
                          _buildSettingsSwitch(
                            icon: Icons.notifications_outlined,
                            title: 'Thông báo',
                            value: _isNotificationsEnabled,
                            theme: theme,
                            onChanged: (val) {
                              setState(() {
                                _isNotificationsEnabled = val;
                              });
                            },
                          ),
                          _buildDivider(),
                          _buildSettingsTile(
                            icon: Icons.info_outline,
                            title: 'Về ứng dụng',
                            theme: theme,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Logout Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<AuthBloc>().add(LogoutEvent());
                          },
                          icon: Icon(Icons.logout, color: theme.colorScheme.error, size: 20),
                          label: Text(
                            'Đăng xuất',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Bottom Navigation overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomNavBar(
                currentIndex: -1,
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
                onMeetingTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RoomListScreen()),
                  );
                },
              ),
            ),
          ],
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required ThemeData theme,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 54, endIndent: 16);
  }
}
