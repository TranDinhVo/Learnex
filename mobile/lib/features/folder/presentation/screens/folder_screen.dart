import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import 'folder_overview_screen.dart';
import 'document_viewer_screen.dart';
import '../../domain/entities/folder_document.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../room/presentation/screens/room_list_screen.dart';
import 'add_document_screen.dart';
import '../../../../shared/utils/file_icon_helper.dart';
import '../../../../shared/widgets/user_account_icon.dart';

class FolderScreen extends StatefulWidget {
  final String? initialSubject;
  const FolderScreen({super.key, this.initialSubject});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<FolderDocument> _cachedDocs = [];
  bool _hasMore = false;
  List<String> _subjects = ['Tất cả'];
  final List<String> _tabs = const ['Tất cả', 'Của tôi', 'Đã lưu'];

  int _selectedSubjectIndex = 0;
  int _selectedTabIndex = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Fetch subjects first
    context.read<DocumentBloc>().add(LoadSubjectsEvent());
    
    if (widget.initialSubject != null) {
      // Will set the index when subjects are loaded
    }
    
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<DocumentBloc>().add(LoadMoreDocumentsEvent());
    }
  }

  void _loadData() {
    final subject = _selectedSubjectIndex == 0 ? null : _subjects[_selectedSubjectIndex];
    
    if (_selectedTabIndex == 0) {
      context.read<DocumentBloc>().add(LoadDocumentsEvent(subject: subject));
    } else if (_selectedTabIndex == 1) {
      context.read<DocumentBloc>().add(LoadMyDocumentsEvent(subject: subject));
    } else if (_selectedTabIndex == 2) {
      context.read<DocumentBloc>().add(LoadSavedDocumentsEvent(subject: subject));
    }
  }

  void _onSubjectChanged(int index) {
    setState(() {
      _selectedSubjectIndex = index;
    });
    _loadData();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _loadData();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature đang được phát triển.')),
    );
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FeedScreen()),
    );
  }

  void _goOverview() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FolderOverviewScreen()),
    );
  }

  void _createPost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  void _goChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  void _goRooms() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoomListScreen()),
    );
  }

  void _openDocument(FolderDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: document)),
    );
  }

  void _toggleSave(FolderDocument document) {
    if (document.id.isEmpty) return;
    context.read<DocumentBloc>().add(ToggleSaveDocumentEvent(documentId: document.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocListener<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is SubjectsLoaded) {
            setState(() {
              _subjects = ['Tất cả', ...state.subjects.map((e) => e['name'].toString())];
              if (widget.initialSubject != null) {
                final index = _subjects.indexOf(widget.initialSubject!);
                if (index != -1) {
                  _selectedSubjectIndex = index;
                  _loadData();
                }
              }
            });
          }
          if (state is DocumentSaveToggled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.isSaved ? 'Đã lưu tài liệu' : 'Đã bỏ lưu tài liệu')),
            );
            _loadData(); // Reload the list to update UI
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
                ),
              ),
            ),
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  elevation: 0,
                  pinned: true,
                  leadingWidth: 56,
                  titleSpacing: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: const Color(0xFF9CA3AF),
                    onPressed: _goOverview,
                  ),
                  title: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tài liệu',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Quản lý folder và học liệu',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.cloud_upload_outlined, color: theme.colorScheme.primary),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDocumentScreen()));
                        _loadData();
                      },
                    ),
                    const UserAccountIcon(),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: _SearchField(onPressed: () {
                      showSearch(context: context, delegate: _DocumentSearchDelegate(context.read<DocumentBloc>()));
                    }),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final selected = index == _selectedSubjectIndex;
                        return ChoiceChip(
                          label: Text(_subjects[index]),
                          selected: selected,
                          onSelected: (_) => _onSubjectChanged(index),
                          backgroundColor: const Color(0xFFE7E8E9),
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : const Color(0xFF4B5563),
                            fontWeight: FontWeight.w600,
                          ),
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: List.generate(_tabs.length, (index) {
                          final selected = index == _selectedTabIndex;
                          return Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _onTabChanged(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? theme.colorScheme.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _tabs[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected ? Colors.white : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                BlocBuilder<DocumentBloc, DocumentState>(
                  builder: (context, state) {
                    if (state is DocumentsLoaded) {
                      final authState = context.read<AuthBloc>().state;
                      final currentUserId = authState is Authenticated ? authState.user.id : null;
                      _cachedDocs = state.documents.map((e) => FolderDocument.fromJson(e, currentUserId: currentUserId)).toList();
                      _hasMore = state.hasMore;
                    } else if (state is DocumentInitial) {
                      _cachedDocs = [];
                      _hasMore = false;
                    }

                    if (state is DocumentLoading && _cachedDocs.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is DocumentError && _cachedDocs.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    if (_cachedDocs.isEmpty && state is! DocumentLoading && state is! DocumentInitial) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Chưa có tài liệu phù hợp.',
                            style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    }

                    return SliverMainAxisGroup(
                      slivers: [
                        if (state is DocumentLoading)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: LinearProgressIndicator(),
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.74,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == _cachedDocs.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final document = _cachedDocs[index];
                                return _FolderDocumentCard(
                                  document: document,
                                  onTap: () => _openDocument(document),
                                  onSaveToggle: () => _toggleSave(document),
                                );
                              },
                              childCount: _hasMore ? _cachedDocs.length + 1 : _cachedDocs.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNavBar(
                currentIndex: 1,
                onHomeTap: _goHome,
                onFolderTap: _goOverview,
                onAddTap: _createPost,
                onChatTap: _goChat,
                onMeetingTap: _goRooms,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: Color(0xFF6B7280)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tìm tài liệu, môn học...',
                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderDocumentCard extends StatelessWidget {
  const _FolderDocumentCard({required this.document, required this.onTap, required this.onSaveToggle});

  final FolderDocument document;
  final VoidCallback onTap;
  final VoidCallback onSaveToggle;

  @override
  Widget build(BuildContext context) {
    final icon = FileIconHelper.getIcon(document.fileUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [document.accent, Colors.white],
                          ),
                        ),
                        child: Center(
                          child: Icon(icon, size: 52, color: document.iconColor),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: onSaveToggle,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Icon(
                              document.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, 
                              size: 18, 
                              color: document.isSaved ? Colors.blue : const Color(0xFF4B5563)
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          document.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: document.iconColor,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE5E7EB),
                              ),
                              child: Center(
                                child: Text(
                                  document.author.isNotEmpty ? document.author[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                document.author,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.download_rounded, size: 14, color: Color(0xFF6B7280)),
                            Text(
                              document.downloads,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentSearchDelegate extends SearchDelegate {
  final DocumentBloc documentBloc;

  _DocumentSearchDelegate(this.documentBloc);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      documentBloc.add(SearchDocumentsEvent(query: query));
    }
    
    return BlocProvider.value(
      value: documentBloc,
      child: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DocumentSearchResults) {
            final documents = state.results.map((e) => FolderDocument.fromJson(e)).toList();
            if (documents.isEmpty) {
              return const Center(child: Text('Không tìm thấy tài liệu nào.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(doc.title),
                  subtitle: Text('${doc.author} - ${doc.category}'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: doc)),
                    );
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Nhập từ khóa để tìm kiếm tài liệu'));
  }
}
