import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/image_parser.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../../../feed/presentation/widgets/post_card.dart';
import '../../../feed/presentation/screens/post_detail_screen.dart';
import '../../../folder/presentation/screens/document_viewer_screen.dart';
import '../../../folder/domain/entities/folder_document.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class GlobalSearchScreen extends StatelessWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const _GlobalSearchScreenView(),
    );
  }
}

class _GlobalSearchScreenView extends StatefulWidget {
  const _GlobalSearchScreenView();

  @override
  State<_GlobalSearchScreenView> createState() => _GlobalSearchScreenViewState();
}

class _GlobalSearchScreenViewState extends State<_GlobalSearchScreenView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _tabTypes = ['all', 'users', 'posts', 'documents'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final currentType = _tabTypes[_tabController.index];
        context.read<SearchBloc>().add(SearchTypeChanged(type: currentType));
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<SearchBloc>().add(SearchLoadMore());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<SearchBloc>().add(const SearchQueryChanged(query: ''));
              },
            ),
          ),
          onChanged: (val) {
            context.read<SearchBloc>().add(SearchQueryChanged(query: val));
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Mọi người'),
            Tab(text: 'Bài viết'),
            Tab(text: 'Tài liệu'),
          ],
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return const Center(
              child: Text('Nhập từ khóa để bắt đầu tìm kiếm.', style: TextStyle(color: Colors.grey)),
            );
          } else if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SearchError) {
            return Center(child: Text('Lỗi: ${state.message}', style: const TextStyle(color: Colors.red)));
          } else if (state is SearchLoaded) {
            return _buildSearchResults(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, SearchLoaded state) {
    final hasResults = (state.results['users']?.isNotEmpty ?? false) ||
        (state.results['posts']?.isNotEmpty ?? false) ||
        (state.results['documents']?.isNotEmpty ?? false);

    if (!hasResults) {
      return const Center(child: Text('Không tìm thấy kết quả nào.', style: TextStyle(color: Colors.grey)));
    }

    final items = <Widget>[];

    // Users
    if (state.results['users'] != null && state.results['users'].isNotEmpty) {
      items.add(const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Mọi người', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ));
      for (var user in state.results['users']) {
        items.add(_buildUserTile(context, user));
      }
    }

    // Posts
    if (state.results['posts'] != null && state.results['posts'].isNotEmpty) {
      items.add(const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Bài viết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ));
      for (var post in state.results['posts']) {
        items.add(_buildPostCard(context, post));
      }
    }

    // Documents
    if (state.results['documents'] != null && state.results['documents'].isNotEmpty) {
      items.add(const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Tài liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ));
      for (var doc in state.results['documents']) {
        items.add(_buildDocumentTile(context, doc));
      }
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index < items.length) return items[index];
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user) {
    final String fullName = user['full_name'] ?? 'User';
    final String username = user['username'] ?? '';
    final String avatarUrl = user['avatar_url'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U') : null,
      ),
      title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('@$username'),
      onTap: () {
        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is Authenticated ? authState.user.id : '';
        final targetUserId = user['id']?.toString() ?? '';

        if (targetUserId == currentUserId) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserProfileScreen(userId: targetUserId)));
        }
      },
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    final name = post['author_name'] ?? 'Học viên Learnex';
    final handle = post['author_username'] != null ? '@${post['author_username']}' : '@student';
    final content = post['content'] ?? '';
    final imageUrls = ImageParser.parseImageUrls(post['image_urls']);
    
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: PostCard(
        authorName: name,
        authorHandle: handle,
        timeAgo: formatTimeAgo(post['created_at']?.toString()),
        authorInitials: name.isNotEmpty ? name[0].toUpperCase() : 'U',
        authorAvatarUrl: post['author_avatar'],
        avatarColor: Colors.indigo.shade100,
        avatarTextColor: Colors.indigo.shade700,
        content: content,
        postType: imageUrls.isNotEmpty
            ? PostType.image
            : (post['document_id'] != null ? PostType.document : PostType.text),
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
        onCommentTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
        },
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, Map<String, dynamic> doc) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40),
      title: Text(doc['title'] ?? 'Document', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(doc['uploader_name'] ?? ''),
      onTap: () {
        if (doc['file_url'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocumentViewerScreen(
                document: FolderDocument.fromJson(doc),
              ),
            ),
          );
        }
      },
    );
  }
}
