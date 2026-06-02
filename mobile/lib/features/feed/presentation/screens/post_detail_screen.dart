import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_item.dart';
import '../widgets/comment_input_bar.dart';
import '../../../../shared/utils/date_formatter.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Map<String, dynamic> _post;
  List<dynamic> _comments = [];
  bool _commentsLoading = true;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final res = await getIt<FeedRepositoryImpl>().getComments(_post['id'].toString());
      final data = res['data'] as List<dynamic>? ?? [];
      setState(() {
        _comments = data;
        _commentsLoading = false;
        _commentsError = null;
      });
    } catch (e) {
      setState(() {
        _commentsError = 'Không thể tải bình luận.';
        _commentsLoading = false;
      });
    }
  }

  Future<void> _addComment(String content) async {
    // Optimistically update comment count
    setState(() {
      final currentCount = _post['comment_count'] as int? ?? 0;
      _post['comment_count'] = currentCount + 1;
    });

    try {
      await getIt<FeedRepositoryImpl>().addComment(_post['id'].toString(), content);
      _loadComments();
    } catch (_) {
      // Revert if error
      setState(() {
        final currentCount = _post['comment_count'] as int? ?? 0;
        _post['comment_count'] = currentCount > 0 ? currentCount - 1 : 0;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi bình luận thất bại. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _toggleLike() async {
    final postId = _post['id'].toString();
    try {
      setState(() {
        final isCurrentlyLiked = _post['is_liked'] == true;
        final currentLikeCount = _post['like_count'] as int? ?? 0;
        _post['is_liked'] = !isCurrentlyLiked;
        _post['like_count'] = isCurrentlyLiked
            ? (currentLikeCount > 0 ? currentLikeCount - 1 : 0)
            : currentLikeCount + 1;
      });
      await getIt<FeedRepositoryImpl>().toggleLike(postId);
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    final postId = _post['id'].toString();
    try {
      setState(() {
        final isCurrentlySaved = _post['is_saved'] == true;
        _post['is_saved'] = !isCurrentlySaved;
      });
      await getIt<FeedRepositoryImpl>().toggleSave(postId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // User initials from AuthBloc
    final authState = context.read<AuthBloc>().state;
    String userInitials = 'U';
    if (authState is Authenticated) {
      final name = authState.user.fullName;
      userInitials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    }

    final authorName = _post['author_name'] ?? 'Học viên Learnex';
    final authorHandle = _post['author_username'] != null 
        ? '@${_post['author_username']}' 
        : '@student';
    final postContent = _post['content'] ?? '';

    String? imageUrl;
    final imageList = _post['image_urls'];
    if (imageList is List && imageList.isNotEmpty) {
      imageUrl = imageList.first as String?;
    } else if (imageList is String && imageList.isNotEmpty) {
      if (imageList.startsWith('[')) {
        imageUrl = imageList.replaceAll(RegExp('[\\[\\]"\' ]'), '');
      } else {
        imageUrl = imageList;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_post);
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
            onPressed: () => Navigator.of(context).pop(_post),
          ),
          title: Text(
            'Bài đăng',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original Post rendered through PostCard
                  PostCard(
                    authorName: authorName,
                    authorHandle: authorHandle,
                    timeAgo: formatTimeAgo(_post['created_at']?.toString()),
                    authorInitials: authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                    avatarColor: Colors.indigo.shade100,
                    avatarTextColor: Colors.indigo.shade700,
                    content: postContent,
                    postType: imageUrl != null
                        ? PostType.image
                        : (_post['document_id'] != null ? PostType.document : PostType.text),
                    imageUrl: imageUrl,
                    documentName: _post['document_title'] ?? 'Tài liệu.pdf',
                    documentSize: _post['document_size'] != null
                        ? '${(_post['document_size'] / 1024).toStringAsFixed(0)} KB'
                        : '1.2 MB',
                    likes: _post['like_count'] ?? 0,
                    comments: _post['comment_count'] ?? 0,
                    isLiked: _post['is_liked'] == true,
                    isSaved: _post['is_saved'] == true,
                    onLikeTap: _toggleLike,
                    onSaveTap: _toggleSave,
                  ),
                  
                  // Comment Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bình luận (${_post['comment_count'] ?? 0})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Comment List Section
                  if (_commentsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_commentsError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(_commentsError!, style: const TextStyle(color: Colors.red)),
                      ),
                    )
                  else if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          'Chưa có bình luận nào. Hãy là người đầu tiên!',
                          style: TextStyle(color: theme.colorScheme.outline, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final cName = comment['author_name'] ?? 'Học viên';
                        final cInitials = cName.isNotEmpty ? cName[0].toUpperCase() : 'U';
                        final cContent = comment['content'] ?? '';
                        
                        return CommentItem(
                          authorName: cName,
                          authorInitials: cInitials,
                          timeAgo: formatTimeAgo(comment['created_at']?.toString()),
                          content: cContent,
                          avatarColor: theme.colorScheme.primaryContainer,
                          avatarTextColor: theme.colorScheme.onPrimaryContainer,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Dynamic Input Bar
          CommentInputBar(
            userInitials: userInitials,
            onSend: _addComment,
          ),
        ],
      ),
    ),
    );
  }
}
