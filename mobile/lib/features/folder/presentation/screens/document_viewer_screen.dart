import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/folder_document.dart';
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../../../../shared/utils/file_icon_helper.dart';
import '../../data/repositories/ai_repository.dart';

class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final FolderDocument document;

  void _openAiAssistant(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (_) => _LearnexAiSheet(document: document),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    // 1. Gửi request báo cho backend biết để tăng số lượt tải (download_count)
    context.read<DocumentBloc>().add(DownloadDocumentEvent(documentId: document.id));

    // 2. Lấy URL gốc của file từ Cloudinary
    String downloadUrl = document.fileUrl;

    // 3. Chèn cờ `fl_attachment` vào Cloudinary URL để ép trình duyệt mobile tải file về thay vì xem trực tiếp
    // Điều này giúp tránh lỗi ERR_INVALID_RESPONSE trên Chrome Android khi mở file raw
    if (downloadUrl.contains('/raw/upload/')) {
      downloadUrl = downloadUrl.replaceFirst('/raw/upload/', '/raw/upload/fl_attachment/');
    } else if (downloadUrl.contains('/image/upload/')) {
      downloadUrl = downloadUrl.replaceFirst('/image/upload/', '/image/upload/fl_attachment/');
    } else if (downloadUrl.contains('/video/upload/')) {
      downloadUrl = downloadUrl.replaceFirst('/video/upload/', '/video/upload/fl_attachment/');
    }

    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || downloadUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có đường dẫn file hợp lệ.')),
        );
      }
      return;
    }

    // 4. Mở trình duyệt ngoài để tiến hành tải file
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở file. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _IconCircleButton(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                document.category,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _IconCircleButton(icon: Icons.download_rounded, onPressed: () => _downloadFile(context)),
                        const SizedBox(width: 4),
                        _IconCircleButton(icon: Icons.share_rounded, onPressed: () {}),
                        if (document.isMine) ...[
                          const SizedBox(width: 4),
                          _IconCircleButton(
                            icon: Icons.delete_outline_rounded,
                            iconColor: Colors.redAccent,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Xoá tài liệu'),
                                  content: const Text('Bạn có chắc chắn muốn xoá tài liệu này không? Hành động này không thể hoàn tác.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Huỷ'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.read<DocumentBloc>().add(DeleteDocumentEvent(documentId: document.id));
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop(); // Go back to folder overview
                                      },
                                      child: const Text('Xoá', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ] else ...[
                          const SizedBox(width: 4),
                          _IconCircleButton(icon: Icons.more_vert_rounded, onPressed: () {}),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 140),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top Cover Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF3525CD), Color(0xFF5A4EE5)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  width: double.infinity,
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          FileIconHelper.getIcon(document.fileUrl),
                                          size: 56,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      Text(
                                        document.title,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Text(
                                          document.chapterTitle,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Body content
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                                  child: Column(
                                    children: [
                                      Text(
                                        document.summary.isNotEmpty ? document.summary : 'Tài liệu chia sẻ kiến thức trên Learnex.',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: const Color(0xFF475569),
                                          height: 1.6,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          _InfoChip(icon: Icons.description_rounded, label: document.fileSize),
                                          _InfoChip(icon: Icons.person_rounded, label: document.author),
                                          _InfoChip(icon: Icons.download_rounded, label: document.downloads),
                                        ],
                                      ),
                                      const SizedBox(height: 48),
                                      // Action area
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Bản xem trước trực tiếp chưa khả dụng. Vui lòng tải xuống.',
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: const Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 56,
                                              child: ElevatedButton.icon(
                                                onPressed: () => _downloadFile(context),
                                                icon: const Icon(Icons.cloud_download_rounded, size: 24, color: Colors.white),
                                                label: const Text(
                                                  'Tải xuống / Xem tài liệu',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF3525CD),
                                                  elevation: 8,
                                                  shadowColor: const Color(0xFF3525CD).withValues(alpha: 0.4),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _AIFab(onPressed: () => _openAiAssistant(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onPressed, this.iconColor});

  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: iconColor ?? const Color(0xFF6B7280)),
        ),
      ),
    );
  }
}

class _ViewerProgressBar extends StatelessWidget {
  const _ViewerProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 4,
      child: Stack(
        children: [
          Container(color: const Color(0xFFF3F4F5)),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: const Color(0xFF3525CD)),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.document});

  final FolderDocument document;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trang ${document.currentPage} / ${document.totalPages}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 16, color: Colors.white24),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: Colors.white54),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _AIFab extends StatelessWidget {
  const _AIFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
      label: const Text(
        'Learnex AI',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3525CD),
        foregroundColor: Colors.white,
        elevation: 12,
        shadowColor: const Color(0x663525CD),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _LearnexAiSheet extends StatefulWidget {
  const _LearnexAiSheet({required this.document});

  final FolderDocument document;

  @override
  State<_LearnexAiSheet> createState() => _LearnexAiSheetState();
}

// Persistent chat history across open/close — keyed by document id
final Map<String, List<Map<String, String>>> _aiChatHistoryCache = {};
final Map<String, String?> _aiSummaryCache = {};

class _LearnexAiSheetState extends State<_LearnexAiSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<Map<String, String>> _messages;
  bool _isLoading = false;
  bool _isSummarizing = false;
  String? _summaryText;

  String get _docId => widget.document.id.isNotEmpty ? widget.document.id : widget.document.title;

  @override
  void initState() {
    super.initState();
    // Restore from session cache
    _messages = _aiChatHistoryCache[_docId] ?? [];
    _summaryText = _aiSummaryCache[_docId];

    // Auto-summarize on first open if we have no summary yet
    if (_summaryText == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoSummarize());
    }
  }

  Future<void> _autoSummarize() async {
    if (!mounted) return;
    setState(() => _isSummarizing = true);
    try {
      final aiRepo = GetIt.instance<AiRepository>();
      final summary = await aiRepo.chat(
        documentTitle: widget.document.title,
        documentDescription: widget.document.summary,
        documentSubject: widget.document.category,
        fileUrl: widget.document.fileUrl,
        messages: [
          {
            'role': 'user',
            'content':
                'Hãy tóm tắt ngắn gọn nội dung của tài liệu "${widget.document.title}" thuộc môn "${widget.document.category}". '
                'Mô tả gốc: "${widget.document.summary.isNotEmpty ? widget.document.summary : 'Chưa có mô tả'}".',
          }
        ],
      );
      if (mounted) {
        setState(() {
          _summaryText = summary;
          _isSummarizing = false;
        });
        _aiSummaryCache[_docId] = summary;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _summaryText = widget.document.summary.isNotEmpty
              ? widget.document.summary
              : 'Không thể tải tóm tắt. Bạn có thể hỏi AI bên dưới.';
          _isSummarizing = false;
        });
        _aiSummaryCache[_docId] = _summaryText;
      }
    }
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _aiChatHistoryCache[_docId] = List.from(_messages);
    _textController.clear();
    _scrollToBottom();

    try {
      final aiRepo = GetIt.instance<AiRepository>();
      final reply = await aiRepo.chat(
        documentTitle: widget.document.title,
        documentDescription: widget.document.summary,
        documentSubject: widget.document.category,
        fileUrl: widget.document.fileUrl,
        messages: _messages,
      );

      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isLoading = false;
        });
        _aiChatHistoryCache[_docId] = List.from(_messages);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _clearHistory() {
    setState(() {
      _messages.clear();
      _summaryText = null;
    });
    _aiChatHistoryCache.remove(_docId);
    _aiSummaryCache.remove(_docId);
    _autoSummarize();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFFFCFCFD),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 40,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1E3E4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3525CD).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF3525CD),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Learnex AI',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF191C1D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Assistant Active',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF777587),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        // --- AI Summary Section ---
                        _AiSection(
                          icon: Icons.summarize_outlined,
                          title: 'Tóm tắt nội dung',
                          child: _isSummarizing
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF3525CD),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'AI đang tóm tắt tài liệu...',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFF9CA3AF),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Text(
                                    _summaryText ?? 'Chưa có tóm tắt.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF464555),
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        // --- Chat Section Header ---
                        if (_messages.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.forum_outlined, color: Color(0xFF6D79F7), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'HỎI ĐÁP VỀ TÀI LIỆU',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _clearHistory,
                                child: Text(
                                  'Xoá lịch sử',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          const _AiSection(
                            icon: Icons.forum_outlined,
                            title: 'Hỏi đáp về tài liệu',
                            child: SizedBox.shrink(),
                          ),
                        const SizedBox(height: 12),
                        ..._messages.map((msg) {
                          final isUser = msg['role'] == 'user';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: isUser
                                ? _UserMessageBubble(
                                    text: msg['content']!,
                                    timeLabel: 'Bạn',
                                  )
                                : _AiMessageBubble(
                                    text: msg['content']!,
                                    timeLabel: 'Learnex AI',
                                  ),
                          );
                        }),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: _AiMessageBubble(
                              text: 'Đang suy nghĩ...',
                              timeLabel: 'Learnex AI',
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCFCFD),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                hintText: 'Hỏi về nội dung tài liệu...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _isLoading ? Colors.grey : const Color(0xFF3525CD),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: _isLoading ? [] : const [
                                BoxShadow(
                                  color: Color(0x403525CD),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _isLoading 
                                ? const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _AiSection extends StatelessWidget {
  const _AiSection({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF6D79F7), size: 16),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _UserMessageBubble extends StatelessWidget {
  const _UserMessageBubble({required this.text, required this.timeLabel});

  final String text;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF3525CD),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.45,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF9CA3AF),
              ),
        ),
      ],
    );
  }
}

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({required this.text, required this.timeLabel});

  final String text;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFC3C0FF),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: const Icon(Icons.psychology_rounded, color: Color(0xFF3525CD), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E3E4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: const Color(0xFFC7C4D8)),
                ),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF191C1D),
                        height: 1.5,
                      ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            timeLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaLine extends StatelessWidget {
  const _FormulaLine({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(left, style: const TextStyle(fontSize: 34, color: Color(0xFF111827))),
        const SizedBox(width: 16),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1)),
          ),
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            right,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextPlaceholderBar extends StatelessWidget {
  const _TextPlaceholderBar({required this.widthFactor, this.height = 8});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

