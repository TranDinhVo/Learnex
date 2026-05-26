import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/story_strip.dart';
import '../widgets/post_card.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import 'package:learnex/shared/utils/date_formatter.dart';
import '../../domain/entities/post.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import 'create_post_screen.dart';
import 'notification_screen.dart';
import 'post_detail_screen.dart';
import '../../../folder/presentation/screens/folder_overview_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../room/presentation/screens/room_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

import '../../../friends/presentation/bloc/friend_bloc.dart';
import '../../../friends/presentation/bloc/friend_event.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // Tải bảng tin và danh sách bạn bè từ API thực tế
    context.read<FeedBloc>().add(LoadFeedEvent());
    context.read<FriendBloc>().add(LoadFriendsEvent());
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
                        icon: Icon(
                          Icons.search,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {},
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
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
                          final post = rawPosts[index] as Map<String, dynamic>;
                          final name =
                              post['author_name'] ?? 'Học viên Learnex';
                          final handle = post['author_username'] != null
                              ? '@${post['author_username']}'
                              : '@student';
                          final content = post['content'] ?? '';
                          final id = post['id']?.toString() ?? '0';
                          final postUserId = post['user_id']?.toString();
                          final authState = context.read<AuthBloc>().state;
                          final currentUserId = authState is Authenticated ? authState.user.id : '';
                          final isOwner = postUserId == currentUserId;

                          String? imageUrl;
                          final imageList = post['image_urls'];
                          if (imageList is List && imageList.isNotEmpty) {
                            imageUrl = imageList.first as String?;
                          } else if (imageList is String &&
                              imageList.isNotEmpty) {
                            if (imageList.startsWith('[')) {
                              imageUrl = imageList.replaceAll(
                                RegExp('[\\[\\]"\' ]'),
                                '',
                              );
                            } else {
                              imageUrl = imageList;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: PostCard(
                              authorName: name,
                              authorHandle: handle,
                              timeAgo: formatTimeAgo(post['created_at']?.toString()),
                              authorInitials: name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : 'U',
                              avatarColor: Colors.indigo.shade100,
                              avatarTextColor: Colors.indigo.shade700,
                              content: content,
                              postType: imageUrl != null
                                  ? PostType.image
                                  : (post['document_id'] != null
                                        ? PostType.document
                                        : PostType.text),
                              imageUrl: imageUrl,
                              documentName:
                                  post['document_title'] ?? 'Tài liệu.pdf',
                              documentSize: post['document_size'] != null
                                  ? '${(post['document_size'] / 1024).toStringAsFixed(0)} KB'
                                  : '1.2 MB',
                              likes: post['like_count'] ?? 0,
                              comments: post['comment_count'] ?? 0,
                              isLiked: post['is_liked'] == true,
                              isSaved: post['is_saved'] == true,
                              onDeleteTap: isOwner
                                  ? () => context.read<FeedBloc>().add(DeletePostEvent(postId: id))
                                  : null,
                              onLikeTap: () {
                                context.read<FeedBloc>().add(LikePostEvent(postId: id));
                              },
                              onSaveTap: () {
                                context.read<FeedBloc>().add(SavePostEvent(postId: id));
                              },
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
                                      MaterialPageRoute(
                                        builder: (_) => const ProfileScreen(),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => UserProfileScreen(userId: postUserId),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        }, childCount: rawPosts.length),
                      ),
                    ),
                ],
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
                // Reload feed
                if (mounted) {
                  context.read<FeedBloc>().add(LoadFeedEvent());
                }
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
}
