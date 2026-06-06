import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'dart:convert';
import '../../domain/models/story_model.dart';
import '../bloc/story_bloc.dart';
import '../bloc/story_event.dart';
import '../widgets/friend_picker_bottom_sheet.dart';
import '../../../../../core/services/websocket_service.dart';
import 'package:video_player/video_player.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final bool isMyStory;
  final String userName;
  final String? userAvatar;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.isMyStory = false,
    required this.userName,
    this.userAvatar,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  Timer? _storyTimer;
  late int _currentIndex;
  final TextEditingController _msgController = TextEditingController();
  final FocusNode _msgFocusNode = FocusNode();
  int _viewCount = 0;
  bool _isSending = false;
  List<Map<String, dynamic>> _viewers = [];
  StreamSubscription? _wsSubscription;
  VideoPlayerController? _videoController;
  
  final List<String> _emojis = ['❤️', '😂', '😮', '😢', '👏'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _animController.addListener(() {
      setState(() {});
    });

    _msgFocusNode.addListener(() {
      if (_msgFocusNode.hasFocus) {
        _animController.stop();
        _storyTimer?.cancel();
        _videoController?.pause();
      } else {
        // Unfocused, resume playing
        _animController.forward();
        _videoController?.play();
        final duration = _animController.duration ?? const Duration(seconds: 5);
        final remaining = duration * (1.0 - _animController.value);
        _storyTimer = Timer(remaining, () {
          _nextStory();
        });
      }
    });

    _startWatching();

    // Lắng nghe real-time view update từ WebSocket
    if (widget.isMyStory) {
      final ws = GetIt.instance<WebSocketService>();
      _wsSubscription = ws.messages.listen((message) {
        if (message['type'] == 'story_view_update' && mounted) {
          final data = message['data'] as Map<String, dynamic>;
          final storyId = data['storyId'];
          if (storyId == widget.stories[_currentIndex].id) {
            setState(() {
              _viewCount = data['viewCount'] as int? ?? _viewCount;
            });
          }
        }
      });
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  void _nextStory() {
    _storyTimer?.cancel();
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startWatching();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    _storyTimer?.cancel();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startWatching();
    }

    _startWatching();
  }

  void _startWatching() async {
    _storyTimer?.cancel();
    final story = widget.stories[_currentIndex];
    
    // Mark as viewed
    context.read<StoryBloc>().add(ViewStoryEvent(storyId: story.id));

    if (widget.isMyStory) {
      try {
        final res = await context.read<StoryBloc>().repository.getStoryViewers(story.id);
        if (mounted) {
          final data = res['data'] as Map<String, dynamic>? ?? {};
          final count = data['viewCount'] as int? ?? 0;
          final viewerList = data['viewers'] as List? ?? [];
          setState(() {
            _viewCount = count;
            _viewers = viewerList.map((v) => v as Map<String, dynamic>).toList();
          });
        }
      } catch (_) {}
    }

    _animController.stop();
    _animController.reset();

    _videoController?.dispose();
    _videoController = null;

    if (story.mediaType == 'video' && story.mediaUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl!));
      try {
        await _videoController!.initialize();
        if (mounted) {
          setState(() {});
          final duration = _videoController!.value.duration;
          _animController.duration = duration;
          _videoController!.play();
          _animController.forward();
          _storyTimer = Timer(duration, () {
            _nextStory();
          });
        }
      } catch (e) {
        // Fallback if video fails to load
        _animController.duration = const Duration(seconds: 5);
        _animController.forward();
        _storyTimer = Timer(const Duration(seconds: 5), () {
          _nextStory();
        });
      }
    } else {
      _animController.duration = const Duration(seconds: 5);
      _animController.forward();
      
      _storyTimer = Timer(const Duration(seconds: 5), () {
        _nextStory();
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_msgFocusNode.hasFocus) {
      _msgFocusNode.unfocus();
      return;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double dx = details.globalPosition.dx;
    final double dy = details.globalPosition.dy;

    // Don't skip if tapping on the bottom 100 pixels (where controls are)
    if (dy > screenHeight - 100) return;

    if (dx < screenWidth / 3) {
      _prevStory();
    } else if (dx > screenWidth * 2 / 3) {
      _nextStory();
    } else {
      // Tap middle (pause) - handled by long press
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _animController.stop();
    _storyTimer?.cancel();
    _videoController?.pause();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_msgFocusNode.hasFocus) return; // wait for keyboard dismiss
    _animController.forward();
    _videoController?.play();
    // Resume timer with remaining time
    final duration = _animController.duration ?? const Duration(seconds: 5);
    final remaining = duration * (1.0 - _animController.value);
    _storyTimer = Timer(remaining, () {
      _nextStory();
    });
  }

  void _showViewerList() {
    // Pause story while sheet is open
    _animController.stop();
    _storyTimer?.cancel();
    _videoController?.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ViewerListSheet(
        viewers: _viewers,
        viewCount: _viewCount,
        storyId: widget.stories[_currentIndex].id,
        bloc: context.read<StoryBloc>(),
      ),
    ).then((_) => _onLongPressEnd(const LongPressEndDetails()));
  }

  void _reactToStory(String emoji) {
    final story = widget.stories[_currentIndex];
    context.read<StoryBloc>().add(ReactStoryEvent(storyId: story.id, emoji: emoji));
    
    // Show a quick floating animation or snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thả $emoji', textAlign: TextAlign.center),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black54,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 100, right: 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    setState(() => _isSending = true);
    
    final story = widget.stories[_currentIndex];
    try {
      final dio = context.read<StoryBloc>().dio;
      await dio.post('/messages', data: {
        'receiverId': story.userId,
        'content': text.trim(),
        'replyToStoryId': story.id,
        'replyStoryPreview': story.textContent ?? 'Đã reply story của bạn',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi tin nhắn')),
        );
        _msgController.clear();
        _msgFocusNode.unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi gửi tin nhắn')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showPrivacyEditor() {
    final story = widget.stories[_currentIndex];
    String selectedVisibility = story.visibility;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Chỉnh sửa quyền riêng tư', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.white),
              title: const Text('Công khai', style: TextStyle(color: Colors.white)),
              trailing: selectedVisibility == 'public' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () => _updatePrivacy('public'),
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.white),
              title: const Text('Bạn bè', style: TextStyle(color: Colors.white)),
              trailing: selectedVisibility == 'friends' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () => _updatePrivacy('friends'),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text('Bạn bè ngoại trừ...', style: TextStyle(color: Colors.white)),
              trailing: selectedVisibility == 'except' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () async {
                Navigator.pop(context, 'open_picker');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.white),
              title: const Text('Chỉ mình tôi', style: TextStyle(color: Colors.white)),
              trailing: selectedVisibility == 'only_me' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () => _updatePrivacy('only_me'),
            ),
          ],
        ),
      ),
    ).then((value) async {
      if (value == 'open_picker') {
        final story = widget.stories[_currentIndex];
        List<String> initial = [];
        try {
          if (story.excludedUserIds != null && story.excludedUserIds!.isNotEmpty) {
            initial = List<String>.from(jsonDecode(story.excludedUserIds!));
          }
        } catch (_) {}
        
        final excludedIds = await FriendPickerBottomSheet.show(context, initial);
        if (excludedIds != null) {
          _updatePrivacy('except', excludedUserIds: excludedIds, popped: true);
        } else {
          _onLongPressEnd(const LongPressEndDetails());
        }
      } else if (value != 'updated') {
        _onLongPressEnd(const LongPressEndDetails());
      }
    });
  }

  Future<void> _updatePrivacy(String visibility, {List<String>? excludedUserIds, bool popped = false}) async {
    final story = widget.stories[_currentIndex];
    final storyBloc = context.read<StoryBloc>();
    final messenger = ScaffoldMessenger.of(context);
    
    if (!popped) Navigator.pop(context, 'updated'); // close modal
    try {
      await storyBloc.dio.put('/stories/${story.id}/privacy', data: {
        'visibility': visibility,
        if (excludedUserIds != null) 'excludedUserIds': excludedUserIds,
      });
      messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật quyền riêng tư')));
      if (mounted) {
        storyBloc.add(LoadStoryFeedEvent()); // Refresh feed
      }
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Lỗi khi cập nhật')));
    }
  }

  void _showStoryOptions() {
    // Pause story while modal is open
    _animController.stop();
    _storyTimer?.cancel();
    _videoController?.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.white),
              title: const Text('Chỉnh sửa quyền riêng tư', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context, 'open_privacy'); // close options menu and signal to open privacy
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa tin', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final story = widget.stories[_currentIndex];
                final storyBloc = context.read<StoryBloc>();
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                
                nav.pop('deleted'); // close options menu
                try {
                  await storyBloc.dio.delete('/stories/${story.id}');
                  messenger.showSnackBar(const SnackBar(content: Text('Đã xóa tin')));
                  if (mounted) {
                    nav.pop(); // Close viewer
                    storyBloc.add(LoadStoryFeedEvent()); // Refresh feed
                  }
                } catch (e) {
                  messenger.showSnackBar(const SnackBar(content: Text('Lỗi khi xóa tin')));
                  if (mounted) _onLongPressEnd(const LongPressEndDetails());
                }
              },
            ),
          ],
        ),
      ),
    ).then((value) {
      if (value == 'open_privacy') {
        _showPrivacyEditor();
      } else if (value != 'deleted') {
        // Resume on close if not deleted
        _onLongPressEnd(const LongPressEndDetails());
      }
    });
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _wsSubscription?.cancel();
    _pageController.dispose();
    _animController.dispose();
    _msgController.dispose();
    _msgFocusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: _onTapDown,
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 10) {
              // Swipe down to close
              Navigator.of(context).pop();
            }
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable standard swipe to handle custom tap regions
                itemCount: widget.stories.length,
                itemBuilder: (context, index) {
                  return _buildStoryItem(widget.stories[index]);
                },
              ),
              
              // Progress Bars
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: List.generate(
                    widget.stories.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            double value = 0.0;
                            if (index < _currentIndex) {
                              value = 1.0;
                            } else if (index == _currentIndex) {
                              value = _animController.value;
                            }
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 3,
                              borderRadius: BorderRadius.circular(2),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Close Button & Header Info
              Positioned(
                top: 30,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: widget.userAvatar != null ? NetworkImage(widget.userAvatar!) : null,
                      child: widget.userAvatar == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          Text(
                            _formatTime(widget.stories[_currentIndex].createdAt), 
                            style: const TextStyle(color: Colors.white70, fontSize: 12)
                          ),
                        ],
                      ),
                    ),
                    if (widget.isMyStory)
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: _showStoryOptions,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Bottom Reactions and Message
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16.0, 
                    right: 16.0, 
                    bottom: MediaQuery.of(context).viewInsets.bottom + 10
                  ),
                  child: widget.isMyStory
                    ? GestureDetector(
                        onTap: _viewCount > 0 ? _showViewerList : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.remove_red_eye, color: Colors.white, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              '$_viewCount người xem',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            // Hiện tối đa 3 emoji tổng hợp từ các viewers đã react
                            ..._viewers
                                .where((v) => v['reactions'] != null && (v['reactions'] as List).isNotEmpty)
                                .expand((v) => (v['reactions'] as List).cast<String>())
                                .toSet()
                                .take(3)
                                .map((emoji) => Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(emoji, style: const TextStyle(fontSize: 16)),
                                    )),
                            if (_viewCount > 0) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 18),
                            ],
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _msgController,
                                      focusNode: _msgFocusNode,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        hintText: 'Nhắn tin...',
                                        hintStyle: TextStyle(color: Colors.white70),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onSubmitted: (text) {
                                        _sendMessage(text);
                                      },
                                    ),
                                  ),
                                  if (_isSending)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12.0),
                                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.send, color: Colors.white),
                                      onPressed: () => _sendMessage(_msgController.text),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ..._emojis.map((emoji) {
                            return GestureDetector(
                              onTap: () => _reactToStory(emoji),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(StoryModel story) {
    if (story.mediaType == 'text') {
      List<Color> gradientColors = [Colors.blue, Colors.purple];
      if (story.bgGradient != null) {
        try {
          final List<dynamic> hexList = jsonDecode(story.bgGradient!);
          gradientColors = hexList.map((hex) => Color(int.parse(hex.toString().replaceFirst('#', '0xFF')))).toList();
        } catch (e) {
          // fallback
        }
      }

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              story.textContent ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else if (story.mediaType == 'video') {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        );
      } else {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }
    } else {
      return Image.network(
        story.mediaUrl ?? '',
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.error, color: Colors.white, size: 48));
        },
      );
    }
  }
}

// ─── Viewer List Bottom Sheet ───────────────────────────────────────────────

class _ViewerListSheet extends StatefulWidget {
  final List<Map<String, dynamic>> viewers;
  final int viewCount;
  final String storyId;
  final StoryBloc bloc;

  const _ViewerListSheet({
    required this.viewers,
    required this.viewCount,
    required this.storyId,
    required this.bloc,
  });

  @override
  State<_ViewerListSheet> createState() => _ViewerListSheetState();
}

class _ViewerListSheetState extends State<_ViewerListSheet> {
  List<Map<String, dynamic>> _viewers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewers = widget.viewers;
    _isLoading = false;
    // Refresh viewers khi mở sheet (để lấy data mới nhất)
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final res = await widget.bloc.repository.getStoryViewers(widget.storyId);
      if (mounted) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final viewerList = data['viewers'] as List? ?? [];
        setState(() {
          _viewers = viewerList.map((v) => v as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_viewers.length} người đã xem',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // List
          Flexible(
            child: _isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  ))
                : _viewers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Chưa có ai xem story này', style: TextStyle(color: Colors.white54)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _viewers.length,
                        itemBuilder: (ctx, i) {
                          final v = _viewers[i];
                          final name = v['full_name']?.toString() ?? v['username']?.toString() ?? 'Người dùng';
                          final avatar = v['avatar_url']?.toString();
                          final emojis = (v['reactions'] as List?)?.cast<String>() ?? [];
                          final viewedAt = v['viewed_at']?.toString();

                          String timeAgo = '';
                          if (viewedAt != null) {
                            try {
                              final t = DateTime.parse(viewedAt).toLocal();
                              final diff = DateTime.now().difference(t);
                              if (diff.inMinutes < 1) timeAgo = 'Vừa xong';
                              else if (diff.inHours < 1) timeAgo = '${diff.inMinutes} phút trước';
                              else if (diff.inDays < 1) timeAgo = '${diff.inHours} giờ trước';
                              else timeAgo = '${diff.inDays} ngày trước';
                            } catch (_) {}
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade700,
                              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                              child: avatar == null
                                  ? Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            subtitle: timeAgo.isNotEmpty
                                ? Text(timeAgo, style: const TextStyle(color: Colors.white54, fontSize: 12))
                                : null,
                            trailing: emojis.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: emojis.map((e) => Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(e, style: const TextStyle(fontSize: 20)),
                                    )).toList(),
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
