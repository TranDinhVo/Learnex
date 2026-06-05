import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learnex/shared/widgets/app_bottom_nav_bar.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../feed/presentation/screens/create_post_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../room/presentation/screens/room_list_screen.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';
import '../../../../shared/widgets/user_account_icon.dart';
import 'folder_screen.dart';
import 'add_document_screen.dart';
import 'document_viewer_screen.dart';
import 'document_search_screen.dart';
import '../../domain/entities/folder_document.dart';
import '../../../../shared/utils/file_icon_helper.dart';

class FolderOverviewScreen extends StatefulWidget {
  const FolderOverviewScreen({super.key});

  @override
  State<FolderOverviewScreen> createState() => _FolderOverviewScreenState();
}

class _FolderOverviewScreenState extends State<FolderOverviewScreen> {
  List<dynamic> _cachedDocs = [];

  @override
  void initState() {
    super.initState();
    // Tải danh sách tài liệu thực tế từ database thông qua DocumentBloc
    context.read<DocumentBloc>().add(LoadDocumentsEvent());
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature đang được phát triển.')));
  }

  void _goHome(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const FeedScreen()));
  }

  void _goFolderDetail(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const FolderScreen()));
  }

  void _createPost(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
  }

  void _goChat(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  void _goRooms(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoomListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          const _OverviewBackground(),
          BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              final isLoading = state is DocumentLoading;
              final errorMsg = state is DocumentError ? state.message : null;
              if (state is DocumentsLoaded) {
                _cachedDocs = state.documents;
              } else if (state is DocumentInitial) {
                _cachedDocs = [];
              }

              // Group documents by subject dynamically
              final Map<String, List<Map<String, dynamic>>> subjectGroups = {};
              for (var d in _cachedDocs) {
                final rawSub = d['subject'] as String?;
                final sub = (rawSub != null && rawSub.trim().isNotEmpty) ? rawSub : 'Khác';
                if (!subjectGroups.containsKey(sub)) {
                  subjectGroups[sub] = [];
                }
                subjectGroups[sub]!.add(d as Map<String, dynamic>);
              }

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 56,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.black12,
                    elevation: 1,
                    pinned: true,
                    titleSpacing: 16,
                    title: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 40,
                            height: 40,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                          color: const Color(0xFF9CA3AF),
                          onPressed: () => _goHome(context),
                        ),
                        const SizedBox(width: 2),
                        const Expanded(
                          child: Text(
                            'Tài liệu',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.cloud_upload_rounded,
                          color: Color(0xFF4F46E5),
                        ),
                        onPressed: () async {
                          final docBloc = context.read<DocumentBloc>();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddDocumentScreen(),
                            ),
                          );
                          if (mounted) {
                            // Load user's own docs so new upload appears immediately
                            docBloc.add(LoadMyDocumentsEvent());
                          }
                        },
                      ),
                      const UserAccountIcon(),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SearchBar(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DocumentSearchScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Thư mục môn học',
                        actionLabel: 'Xem tất cả',
                        onActionTap: () => _goFolderDetail(context),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16.0),
                              child: LinearProgressIndicator(),
                            ),
                          if (!isLoading && subjectGroups.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'Không có môn học nào.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ),
                            )
                          else if (subjectGroups.isNotEmpty)
                            GridView.extent(
                              maxCrossAxisExtent: 200,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.02,
                              children: subjectGroups.entries.map((entry) {
                                return _FolderMiniCard(
                                  title: entry.key,
                                  countLabel: '${entry.value.length} tài liệu',
                                  icon: Icons.folder_rounded,
                                  accent: const Color(0xFFE2DFFF),
                                  iconColor: const Color(0xFF3525CD),
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => FolderScreen(initialSubject: entry.key)),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Tài liệu học tập',
                        actionWidget: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                          onPressed: () => _showComingSoon(context, 'Sắp xếp'),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
                    sliver: isLoading
                        ? const SliverToBoxAdapter(child: SizedBox())
                        : (errorMsg != null
                              ? SliverToBoxAdapter(
                                  child: Center(
                                    child: Text(
                                      'Lỗi: $errorMsg',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                )
                              : (_cachedDocs.isEmpty
                                    ? const SliverToBoxAdapter(
                                        child: Center(
                                          child: Text(
                                            'Chưa có tài liệu nào được đăng.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      )
                                    : SliverList(
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          final doc =
                                              _cachedDocs[index]
                                                  as Map<String, dynamic>;
                                          final title =
                                              doc['title'] ??
                                              'Tài liệu không tên';
                                          final rawSize = doc['file_size'];
                                          final sizeNum = rawSize is num
                                              ? rawSize
                                              : (rawSize is String ? num.tryParse(rawSize) : null);
                                          final size = sizeNum != null
                                              ? '${(sizeNum / 1024).toStringAsFixed(0)} KB'
                                              : '1.5 MB';

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12.0,
                                            ),
                                            child: _RecentDocumentCard(
                                              title: title,
                                              sizeLabel: size,
                                              dateLabel: 'Vừa xong',
                                              icon: FileIconHelper.getIcon(doc['file_url']),
                                              iconBackground: FileIconHelper.getBackgroundColor(doc['file_url']),
                                              iconColor: FileIconHelper.getColor(doc['file_url']),
                                              onTap: () {
                                                final authState = context.read<AuthBloc>().state;
                                                final currentUserId = authState is Authenticated ? authState.user.id : null;
                                                final folderDoc = FolderDocument.fromJson(doc, currentUserId: currentUserId);
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: folderDoc)),
                                                );
                                              },
                                            ),
                                          );
                                        }, childCount: _cachedDocs.length),
                                      ))),
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavBar(
              currentIndex: 1,
              onHomeTap: () => _goHome(context),
              onFolderTap: () {},
              onAddTap: () => _createPost(context),
              onChatTap: () => _goChat(context),
              onMeetingTap: () => _goRooms(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewBackground extends StatelessWidget {
  const _OverviewBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -40,
          right: -100,
          child: _GlowBlob(
            color: const Color(0xFFDAD7FF).withValues(alpha: 0.45),
            size: 220,
          ),
        ),
        Positioned(
          top: 120,
          left: -80,
          child: _GlowBlob(
            color: const Color(0xFFF3F4F5).withValues(alpha: 0.8),
            size: 150,
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE1E3E4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF777587), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tìm kiếm tài liệu...',
                  style: TextStyle(
                    color: Color(0xFF777587),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.actionWidget,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final Widget? actionWidget;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF191C1D),
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionWidget != null)
          actionWidget!
        else if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: Color(0xFF3525CD),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class _FolderMiniCard extends StatelessWidget {
  const _FolderMiniCard({
    required this.title,
    required this.countLabel,
    required this.icon,
    required this.accent,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String countLabel;
  final IconData icon;
  final Color accent;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A3525CD),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191C1D),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                countLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDocumentCard extends StatelessWidget {
  const _RecentDocumentCard({
    required this.title,
    required this.sizeLabel,
    required this.dateLabel,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String sizeLabel;
  final String dateLabel;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A3525CD),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF191C1D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          sizeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC7C4D8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
