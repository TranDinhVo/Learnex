import 'package:flutter/material.dart';
import '../../domain/enums/post_visibility.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../widgets/story_strip.dart';
import '../widgets/post_card.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import 'package:learnex/shared/utils/date_formatter.dart';
import 'package:learnex/shared/utils/image_parser.dart';
import 'package:learnex/shared/widgets/user_account_icon.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../room/presentation/screens/room_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../search/presentation/screens/global_search_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'package:learnex/shared/widgets/notification_bell.dart';

import '../../../friends/presentation/bloc/friend_bloc.dart';
import '../../../friends/presentation/bloc/friend_event.dart';
import '../../../friends/presentation/screens/friends_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tải bảng tin và danh sách bạn bè từ API thực tế
    context.read<FeedBloc>().add(LoadFeedEvent());
    context.read<FriendBloc>().add(LoadFriendsEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showLikersBottomSheet(BuildContext context, String postId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Lượt thích',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: getIt<FeedRepositoryImpl>().getLikers(postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Đã có lỗi xảy ra'));
                  }
                  final likers = snapshot.data ?? [];
                  if (likers.isEmpty) {
                    return const Center(child: Text('Chưa có lượt thích nào.'));
                  }
                  return ListView.builder(
                    itemCount: likers.length,
                    itemBuilder: (context, index) {
                      final liker = likers[index];
                      final name = liker['full_name'] ?? 'U';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: liker['avatar_url'] != null
                              ? NetworkImage(liker['avatar_url'])
                              : null,
                          child: liker['avatar_url'] == null
                              ? Text(name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('@${liker['username']}'),
                        onTap: () {
                          Navigator.pop(context);
                          final likerId = liker['id']?.toString();
                          if (likerId != null) {
                            final authState = context.read<AuthBloc>().state;
                            final currentUserId = authState is Authenticated ? authState.user.id : '';
                            if (likerId == currentUserId) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => UserProfileScreen(userId: likerId)),
                              );
                            }
                          }
                        },
                      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          BlocBuilder<FeedBloc, FeedState>(
            builder: (context, state) {
              final isLoading = state is FeedLoading;
              final errorMsg = state is FeedError ? state.message : null;
              List<dynamic> rawPosts = [];

              if (state is FeedLoaded) {
                rawPosts = state.posts;
              } else if (state is FeedLoadingMore) {
                rawPosts = state.currentPosts;
              }

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Top App Bar implementation using SliverAppBar
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
                        icon: Icon(Icons.people_outline, color: theme.colorScheme.onSurfaceVariant),
                        tooltip: 'Bạn bè',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FriendsScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                          );
                        },
                      ),
                      NotificationBell(iconColor: theme.colorScheme.onSurfaceVariant),
                      const UserAccountIcon(),
                    ],
                  ),

                  // Story Strip Content
                  const SliverPadding(
                    padding: EdgeInsets.only(
                      top: 16.0,
                      left: 16.0,
                      right: 16.0,
                      bottom: 24.0,
                    ),
                    sliver: SliverToBoxAdapter(child: StoryStrip()),
                  ),

                  // Feed Content
                  if (isLoading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                          childCount: 3,
                        ),
                      ),
                    )
                  else if (errorMsg != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'Đã có lỗi xảy ra: $errorMsg',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    )
                  else if (rawPosts.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'Chưa có bài viết nào.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 100.0,
                      ), // padding bottom for fab/nav
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          try {
                            final post = rawPosts[index] as Map<String, dynamic>;
                            final name = post['author_name'] ?? 'Học viên Learnex';
                            final handle = post['author_username'] != null
                                ? '@${post['author_username']}'
                                : '@student';
                            final content = post['content'] ?? '';
                            final id = post['id']?.toString() ?? '0';
                            final postUserId = post['user_id']?.toString();
                            final authState = context.read<AuthBloc>().state;
                            final currentUserId = authState is Authenticated ? authState.user.id : '';
                            final isOwner = postUserId == currentUserId;

                            final imageUrls = ImageParser.parseImageUrls(post['image_urls']);

                            // Safe parse document_size — server may return String or num
                            String? docSize;
                            final rawSize = post['document_size'];
                            if (rawSize != null) {
                              try {
                                final sizeNum = rawSize is num ? rawSize : num.parse(rawSize.toString());
                                docSize = '${(sizeNum / 1024).toStringAsFixed(0)} KB';
                              } catch (_) {
                                docSize = rawSize.toString();
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: PostCard(
                                authorName: name,
                                authorHandle: handle,
                                timeAgo: formatTimeAgo(post['created_at']?.toString()),
                                authorInitials: name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                authorAvatarUrl: post['author_avatar'] as String?,
                                avatarColor: Colors.indigo.shade100,
                                avatarTextColor: Colors.indigo.shade700,
                                content: content,
                                postType: imageUrls.isNotEmpty
                                    ? PostType.image
                                    : (post['document_id'] != null
                                          ? PostType.document
                                          : PostType.text),
                                location: post['location'] as String?,
                                imageUrls: imageUrls,
                                taggedUsers: post['tagged_users'] as List<dynamic>?,
                                documentName: post['document_title']?.toString() ?? 'Tài liệu',
                                documentSize: docSize,
                                documentUrl: post['document_url']?.toString(),
                                visibility: post['visibility']?.toString(),
                                likes: post['like_count'] ?? 0,
                                comments: post['comment_count'] ?? 0,
                                isLiked: post['is_liked'] == true,
                                isSaved: post['is_saved'] == true,
                                onEditTap: isOwner ? () {
                                  _showPrivacyEditBottomSheet(context, id, post['visibility']?.toString() ?? 'friends', post);
                                } : null,
                                onDeleteTap: isOwner
                                    ? () => context.read<FeedBloc>().add(DeletePostEvent(postId: id))
                                    : null,
                                onLikeTap: () {
                                  context.read<FeedBloc>().add(LikePostEvent(postId: id));
                                },
                                onSaveTap: () {
                                  context.read<FeedBloc>().add(SavePostEvent(postId: id));
                                },
                                onLikersTap: () => _showLikersBottomSheet(context, id),
                                onCommentTap: () async {
                                  final updated = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PostDetailScreen(post: post),
                                    ),
                                  );
                                  if (updated != null && context.mounted) {
                                    context.read<FeedBloc>().add(UpdatePostInListEvent(updatedPost: updated));
                                  }
                                },
                                onAuthorTap: () {
                                  final postUserId = post['user_id']?.toString();
                                  if (postUserId != null) {
                                    final authState = context.read<AuthBloc>().state;
                                    final currentUserId = authState is Authenticated ? authState.user.id : '';
                                    if (postUserId == currentUserId) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                      );
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: postUserId)),
                                      );
                                    }
                                  }
                                },
                                onTaggedUserTap: (taggedUserId) {
                                  final authState = context.read<AuthBloc>().state;
                                  final currentUserId = authState is Authenticated ? authState.user.id : '';
                                  if (taggedUserId == currentUserId) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: taggedUserId)),
                                    );
                                  }
                                },
                              ),
                            );
                          } catch (e) {
                            // Nếu có lỗi khi render bài đăng, hiện placeholder thay vì crash
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.grey.shade400),
                                    const SizedBox(width: 12),
                                    Text('Không thể hiển thị bài đăng này.',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                  ],
                                ),
                              ),
                            );
                          }
                        }, childCount: rawPosts.length),
                      ),
                    ),
                ],
              );
            },
          ),

          // Banner: New Posts
          BlocBuilder<FeedBloc, FeedState>(
            builder: (context, state) {
              int pendingCount = 0;
              if (state is FeedLoaded) {
                pendingCount = state.pendingNewPosts.length;
              }
              if (pendingCount == 0) return const SizedBox.shrink();

              return Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<FeedBloc>().add(MergePendingPostsEvent());
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Có $pendingCount bài viết mới',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom Navigation overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNavBar(
              currentIndex: 0,
              onHomeTap: () {},
              onFolderTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const FolderOverviewScreen(),
                  ),
                );
              },
              onAddTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
                // WS feed_new_post will handle adding the new post to the list automatically
              },
              onChatTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const ChatListScreen(),
                  ),
                );
              },
              onMeetingTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const RoomListScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void _showPrivacyEditBottomSheet(BuildContext context, String postId, String currentVisibility, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Chỉnh sửa quyền riêng tư', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildPrivacyOption(ctx, postId, post, 'public', 'Công khai', Icons.public, currentVisibility == 'public'),
              _buildPrivacyOption(ctx, postId, post, 'friends', 'Bạn bè', Icons.group, currentVisibility == 'friends'),
              _buildPrivacyOption(ctx, postId, post, 'except', 'Loại trừ', Icons.people_outline, currentVisibility == 'except'),
              _buildPrivacyOption(ctx, postId, post, 'private', 'Chỉ mình tôi', Icons.lock, currentVisibility == 'private'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyOption(BuildContext ctx, String postId, Map<String, dynamic> post, String value, String label, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : null),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.blue : null, fontWeight: isSelected ? FontWeight.bold : null)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        Navigator.of(ctx).pop();
        if (!isSelected) {
          context.read<FeedBloc>().add(EditPostEvent(
            postId: postId,
            content: post['content'],
            visibility: PostVisibility.values.firstWhere((e) => e.value == value, orElse: () => PostVisibility.friends),
          ));
        }
      },
    );
  }
}
