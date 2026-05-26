import 'package:flutter/material.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';

import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import 'folder_overview_screen.dart';
import 'document_viewer_screen.dart';
import '../../domain/entities/folder_document.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../room/presentation/screens/room_list_screen.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final List<String> _subjects = const [
    'Tất cả',
    'Lập trình',
    'Toán học',
    'Vật lý',
    'Triết học',
    'Tiếng Anh',
  ];

  final List<String> _tabs = const [
    'Tất cả',
    'Của tôi',
    'Đã lưu',
  ];

  final List<FolderDocument> _documents = const [
    FolderDocument(
      title: 'Giải tích 2 - Tổng hợp',
      fileName: 'Giải tích 2 - Tổng hợp.pdf',
      category: 'Toán học',
      type: DocumentType.pdf,
      author: 'HoangAn',
      downloads: '1.2k',
      fileSize: '4.2 MB',
      currentPage: 1,
      totalPages: 24,
      chapterTitle: 'Chương 1: Tích phân không xác định',
      summary: 'Bộ tài liệu tổng hợp các công thức, ví dụ và bài tập trọng tâm cho học phần Giải tích 2.',
      accent: Color(0xFFFEE2E2),
      iconColor: Color(0xFFEF4444),
      isMine: true,
      isSaved: true,
    ),
    FolderDocument(
      title: 'Slide CNPM ch.1-5',
      fileName: 'Slide-CNPM-ch1-5.pptx',
      category: 'Lập trình',
      type: DocumentType.presentation,
      author: 'ThuyLinh',
      downloads: '450',
      fileSize: '18.6 MB',
      currentPage: 1,
      totalPages: 46,
      chapterTitle: 'Tổng quan dự án phần mềm',
      summary: 'Slide bài giảng cho các buổi đầu của môn Công nghệ Phần mềm.',
      accent: Color(0xFFFFEDD5),
      iconColor: Color(0xFFF97316),
      isMine: false,
      isSaved: true,
    ),
    FolderDocument(
      title: 'Kiến trúc máy tính',
      fileName: 'Kien-truc-may-tinh.docx',
      category: 'Lập trình',
      type: DocumentType.doc,
      author: 'MinhDuc',
      downloads: '892',
      fileSize: '6.8 MB',
      currentPage: 1,
      totalPages: 18,
      chapterTitle: 'Bộ nhớ và tổ chức máy tính',
      summary: 'Ghi chú ngắn gọn về kiến trúc máy tính và các câu hỏi ôn tập thường gặp.',
      accent: Color(0xFFDBEAFE),
      iconColor: Color(0xFF3B82F6),
      isMine: true,
      isSaved: false,
    ),
    FolderDocument(
      title: 'Source code BT lớn',
      fileName: 'Source-code-BT-lon.zip',
      category: 'Lập trình',
      type: DocumentType.zip,
      author: 'DevHacker',
      downloads: '2.1k',
      fileSize: '31.4 MB',
      currentPage: 1,
      totalPages: 12,
      chapterTitle: 'Mẫu source code và tài nguyên',
      summary: 'Gói mã nguồn tham khảo cho bài tập lớn và project cuối kỳ.',
      accent: Color(0xFFE9D5FF),
      iconColor: Color(0xFF8B5CF6),
      isMine: false,
      isSaved: false,
    ),
  ];

  int _selectedSubjectIndex = 0;
  int _selectedTabIndex = 0;

  List<FolderDocument> get _visibleDocuments {
    return _documents.where((document) {
      final subjectMatch = _selectedSubjectIndex == 0 || document.category == _subjects[_selectedSubjectIndex];
      final tabMatch = switch (_selectedTabIndex) {
        1 => document.isMine,
        2 => document.isSaved,
        _ => true,
      };
      return subjectMatch && tabMatch;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
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
                    onPressed: () => _showComingSoon('Tải lên'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _SearchField(onPressed: () => _showComingSoon('Tìm kiếm')),
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
                        onSelected: (_) => setState(() => _selectedSubjectIndex = index),
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
                            onTap: () => setState(() => _selectedTabIndex = index),
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
              if (_visibleDocuments.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Chưa có tài liệu phù hợp.',
                      style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.74,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final document = _visibleDocuments[index];
                        return _FolderDocumentCard(
                          document: document,
                          onTap: () => _openDocument(document),
                        );
                      },
                      childCount: _visibleDocuments.length,
                    ),
                  ),
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
  const _FolderDocumentCard({required this.document, required this.onTap});

  final FolderDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (document.type) {
      DocumentType.pdf => Icons.picture_as_pdf_rounded,
      DocumentType.presentation => Icons.slideshow_rounded,
      DocumentType.doc => Icons.description_rounded,
      DocumentType.zip => Icons.folder_zip_rounded,
    };

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
                          child: const Icon(Icons.bookmark_border_rounded, size: 18, color: Color(0xFF4B5563)),
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
