import 'package:flutter/material.dart';
import '../widgets/story_strip.dart';
import '../widgets/post_card.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';
import '../../domain/entities/post.dart';
import '../../data/repositories/mock_feed_repository.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final MockFeedRepository _repository = MockFeedRepository();
  bool _isLoading = true;
  String? _error;
  List<PostEntity> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _repository.getFeedPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top App Bar implementation using SliverAppBar
              SliverAppBar(
                backgroundColor: Colors.white.withOpacity(0.9),
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
                    icon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () {},
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications_none, color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {},
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
                            border: Border.all(color: Colors.white, width: 1.5),
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
                padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 24.0),
                sliver: SliverToBoxAdapter(
                  child: StoryStrip(),
                ),
              ),

              // Feed Content
              if (_isLoading)
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
                          child: CircularProgressIndicator(color: theme.colorScheme.primary.withOpacity(0.5)),
                        ),
                      ),
                      childCount: 3,
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Center(child: Text('Đã có lỗi xảy ra: $_error')),
                )
              else if (_posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(child: Text('Chưa có bài viết nào.', style: TextStyle(color: Colors.grey))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 100.0), // padding bottom for fab/nav
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = _posts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: PostCard(
                            authorName: post.authorName,
                            authorHandle: post.authorHandle,
                            timeAgo: post.timeAgo,
                            authorInitials: post.authorInitials,
                            avatarColor: post.avatarColor,
                            avatarTextColor: post.avatarTextColor,
                            content: post.content,
                            postType: post.type,
                            imageUrl: post.imageUrl,
                            documentName: post.documentName,
                            documentSize: post.documentSize,
                            likes: post.likes,
                            comments: post.comments,
                          ),
                        );
                      },
                      childCount: _posts.length,
                    ),
                  ),
                ),
            ],
          ),
          
          // Bottom Navigation overlay
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNavBar(),
          ),
        ],
      ),
    );
  }
}
