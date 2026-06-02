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
import '../../../../shared/utils/image_parser.dart';
import 'edit_post_screen.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
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

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
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

  Future<void> _submitComment(String content) async {
    if (_editingCommentId != null) {
      await _updateComment(_editingCommentId!, content);
    } else {
      await _addComment(content);
    }
  }

  Future<void> _updateComment(String commentId, String content) async {
    final previousComments = List.from(_comments);
    setState(() {
      final index = _comments.indexWhere((c) => c['id'].toString() == commentId);
      if (index != -1) {
        _comments[index] = {
          ..._comments[index],
          'content': content,
          'is_edited': true,
        };
      }
      _editingCommentId = null;
      _commentController.clear();
      _commentFocusNode.unfocus();
    });

    try {
      await getIt<FeedRepositoryImpl>().updateComment(_post['id'].toString(), commentId, content);
    } catch (_) {
      setState(() {
        _comments = previousComments;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật bình luận thất bại.')),
        );
      }
    }
  }

  Future<void> _addComment(String content) async {
    // Optimistically update comment count
    setState(() {
      final currentCount = _post['comment_count'] as int? ?? 0;
      _post['comment_count'] = currentCount + 1;
      _commentController.clear();
    });

    try {
      await getIt<FeedRepositoryImpl>().addComment(_post['id'].toString(), content);
      _loadComments();
    } catch (_) {
      // Revert if error
      if (mounted) {
        setState(() {
          final currentCount = _post['comment_count'] as int? ?? 0;
          _post['comment_count'] = currentCount > 0 ? currentCount - 1 : 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi bình luận thất bại. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    // Optimistically update comment count and remove from list
    final previousComments = List.from(_comments);
    setState(() {
      final currentCount = _post['comment_count'] as int? ?? 0;
      _post['comment_count'] = currentCount > 0 ? currentCount - 1 : 0;
      _comments.removeWhere((c) => c['id'].toString() == commentId);
    });

    try {
      await getIt<FeedRepositoryImpl>().deleteComment(_post['id'].toString(), commentId);
    } catch (_) {
      // Revert if error
      setState(() {
        _post['comment_count'] = previousComments.length;
        _comments = previousComments;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa bình luận thất bại.')),
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
    String currentUserId = '';
    if (authState is Authenticated) {
      final name = authState.user.fullName;
      userInitials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
      currentUserId = authState.user.id;
    }
    
    final isOwner = _post['user_id']?.toString() == currentUserId;

    final authorName = _post['author_name'] ?? 'Học viên Learnex';
    final authorHandle = _post['author_username'] != null 
        ? '@${_post['author_username']}' 
        : '@student';
    final postContent = _post['content'] ?? '';

    final imageUrls = ImageParser.parseImageUrls(_post['image_urls']);

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
          actions: [
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Xóa bài viết?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text('Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            context.read<FeedBloc>().add(DeletePostEvent(postId: _post['id'].toString()));
                            Navigator.of(context).pop(); // Return to previous screen, returning null
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa bài viết')),
                            );
                          },
                          child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
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
                    authorAvatarUrl: _post['author_avatar'] as String?,
                    avatarColor: Colors.indigo.shade100,
                    avatarTextColor: Colors.indigo.shade700,
                    content: postContent,
                    postType: imageUrls.isNotEmpty
                        ? PostType.image
                        : (_post['document_id'] != null ? PostType.document : PostType.text),
                    imageUrls: imageUrls,
                    documentName: _post['document_title'] as String? ?? 'Tài liệu',
                    documentSize: _post['document_size'] != null
                        ? '${((_post['document_size'] as num) / 1024).toStringAsFixed(0)} KB'
                        : null,
                    documentUrl: _post['document_url'] as String?,
                    taggedUsers: _post['tagged_users'] as List<dynamic>?,
                    visibility: _post['visibility']?.toString(),
                    likes: _post['like_count'] ?? 0,
                    comments: _post['comment_count'] ?? 0,
                    isLiked: _post['is_liked'] == true,
                    isSaved: _post['is_saved'] == true,
                    onLikeTap: _toggleLike,
                    onSaveTap: _toggleSave,
                    onEditTap: isOwner ? () async {
                      try {
                        final updated = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditPostScreen(post: _post),
                          ),
                        );
                        if (updated != null && mounted) {
                          setState(() {
                            _post = updated as Map<String, dynamic>;
                          });
                          context.read<FeedBloc>().add(UpdatePostInListEvent(updatedPost: updated));
                        }
                      } catch (e, stackTrace) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                        print('Lỗi EditPostScreen: $e\n$stackTrace');
                      }
                    } : null,
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
                        final isCommentOwner = comment['user_id']?.toString() == currentUserId;
                        
                        return CommentItem(
                          authorName: cName,
                          authorInitials: cInitials,
                          timeAgo: formatTimeAgo(comment['created_at']?.toString()),
                          content: cContent,
                          avatarColor: theme.colorScheme.primaryContainer,
                          avatarTextColor: theme.colorScheme.onPrimaryContainer,
                          authorAvatarUrl: comment['author_avatar'] as String?,
                          isEdited: comment['is_edited'] == true,
                          onEditTap: isCommentOwner ? () {
                            setState(() {
                              _editingCommentId = comment['id'].toString();
                              _commentController.text = cContent;
                            });
                            _commentFocusNode.requestFocus();
                          } : null,
                          onDeleteTap: isCommentOwner ? () {
                            _deleteComment(comment['id'].toString());
                          } : null,
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
            onSend: _submitComment,
            controller: _commentController,
            focusNode: _commentFocusNode,
            isEditing: _editingCommentId != null,
            onCancelEdit: () {
              setState(() {
                _editingCommentId = null;
              });
            },
          ),
        ],
      ),
    ),
    );
  }
}
