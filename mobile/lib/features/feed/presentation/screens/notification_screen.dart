import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../app/di.dart';
import '../../../../shared/utils/date_formatter.dart';
import 'post_detail_screen.dart';
import '../../../room/presentation/screens/room_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<_NotificationItemData> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final response = await getIt<Dio>().get('/notifications?page=1&limit=50');
      final list = response.data['data'] as List<dynamic>? ?? [];

      setState(() {
        _notifications = list.map((json) {
          final bodyText = json['body']?.toString() ?? '';
          final titleText = json['title']?.toString() ?? '';
          final textToParse = bodyText.isNotEmpty ? bodyText : titleText;
          
          // Parse name and Vietnamese message from text
          String parsedName = 'Học viên';
          String parsedMessage = textToParse;
          if (textToParse.contains(' liked your post.')) {
            parsedName = textToParse.split(' liked your post.').first;
            parsedMessage = 'đã thích bài đăng của bạn';
          } else if (textToParse.contains(' commented on your post.')) {
            parsedName = textToParse.split(' commented on your post.').first;
            parsedMessage = 'đã bình luận vào bài đăng của bạn';
          } else if (textToParse.contains(' sent you a friend request.')) {
            parsedName = textToParse.split(' sent you a friend request.').first;
            parsedMessage = 'đã gửi lời mời kết bạn cho bạn';
          } else if (textToParse.contains(' accepted your friend request.')) {
            parsedName = textToParse.split(' accepted your friend request.').first;
            parsedMessage = 'đã đồng ý kết bạn';
          } else if (textToParse.contains(' đã gắn thẻ bạn trong một bài viết.')) {
            parsedName = textToParse.split(' đã gắn thẻ bạn trong một bài viết.').first;
            parsedMessage = 'đã gắn thẻ bạn trong một bài viết.';
          } else if (bodyText.contains(' invited you to join ')) {
            final parts = bodyText.split(' invited you to join ');
            parsedName = parts.first;
            final roomName = parts.last.replaceAll('"', '');
            parsedMessage = 'đã mời bạn vào phòng $roomName';
          } else {
            final words = textToParse.split(' ');
            if (words.length > 2) {
              parsedName = words.take(2).join(' ');
              parsedMessage = words.skip(2).join(' ');
            }
          }

          // Choose icon and colors based on notification type
          final type = json['type']?.toString() ?? 'default';
          IconData iconData = Icons.notifications;
          Color iconBg = const Color(0xFF777587);
          if (type == 'like') {
            iconData = Icons.favorite;
            iconBg = const Color(0xFFBA1A1A);
          } else if (type == 'comment') {
            iconData = Icons.chat_bubble;
            iconBg = const Color(0xFF3525CD);
          } else if (type == 'friend_request') {
            iconData = Icons.person_add;
            iconBg = const Color(0xFF10B981);
          } else if (type == 'friend_accept') {
            iconData = Icons.people;
            iconBg = const Color(0xFF10B981);
          } else if (type == 'message') {
            iconData = Icons.chat;
            iconBg = const Color(0xFF4F46E5);
          } else if (type == 'tag') {
            iconData = Icons.sell;
          } else if (type == 'room_invite') {
            iconData = Icons.meeting_room;
            iconBg = const Color(0xFFF59E0B);
          }

          return _NotificationItemData(
            id: json['id']?.toString() ?? '',
            name: parsedName,
            message: parsedMessage,
            timeAgo: formatTimeAgo(json['created_at']?.toString()),
            icon: iconData,
            iconBackground: iconBg,
            avatarUrl: '', // Will fallback to initials in UI
            avatarBackground: const Color(0xFFEDEEFF),
            isUnread: json['is_read'] != true,
            type: type,
            refType: json['ref_type']?.toString(),
            refId: json['ref_id']?.toString(),
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách thông báo.';
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    // Optimistic update
    setState(() {
      _notifications = _notifications.map((item) {
        if (item.id == id) {
          return item.copyWith(isUnread: false);
        }
        return item;
      }).toList();
    });

    try {
      await getIt<Dio>().post('/notifications/$id/read');
    } catch (_) {
      // Revert or ignore
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((item) => item.copyWith(isUnread: false)).toList();
    });

    try {
      await getIt<Dio>().post('/notifications/read-all');
    } catch (_) {}
  }

  List<_NotificationItemData> get _newNotifications =>
      _notifications.where((item) => item.isUnread).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _newNotifications.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          const _NotificationBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leadingWidth: 56,
                titleSpacing: 8,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: const Color(0xFF4F46E5),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Thông báo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3123CC),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.done_all_rounded),
                    color: const Color(0xFF4F46E5),
                    onPressed: unreadCount == 0 ? null : _markAllAsRead,
                    tooltip: 'Đánh dấu tất cả đã đọc',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _NotificationSection(
                          title: 'Tất cả thông báo',
                          child: Column(
                            children: [
                              if (_notifications.isEmpty)
                                const _EmptyStateCard(
                                  icon: Icons.notifications_off_outlined,
                                  title: 'Không có thông báo nào',
                                  subtitle: 'Những cập nhật mới sẽ xuất hiện ở đây.',
                                )
                              else
                                ..._notifications.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _NotificationTile(
                                      item: item,
                                      unread: item.isUnread,
                                      onTap: () {
                                        if (item.isUnread) {
                                          _markAsRead(item.id);
                                        }
                                        _handleNotificationTap(item);
                                      },
                                    ),
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
        ],
      ),
    );
  }

  void _handleNotificationTap(_NotificationItemData item) async {
    if (item.refType == 'post' && item.refId != null) {
      try {
        final res = await getIt<Dio>().get('/posts/${item.refId}');
        final post = res.data['data'] ?? res.data;
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post),
            ),
          );
        }
      } catch (_) {}
    } else if (item.type == 'room_invite' && item.refId != null) {
      _showRoomInviteDialog(item);
    }
  }

  void _showRoomInviteDialog(_NotificationItemData item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lời mời vào phòng'),
        content: Text('${item.name} ${item.message}. Bạn có muốn tham gia không?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Delete notification
                await getIt<Dio>().delete('/notifications/${item.id}');
                _loadNotifications();
              } catch (_) {}
            },
            child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Call join API
                await getIt<Dio>().post('/rooms/${item.refId}/join');
                if (mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RoomDetailScreen(roomId: item.refId!),
                  ));
                }
                _loadNotifications();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể tham gia phòng hoặc đã hết hạn.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Tham gia', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _NotificationBackground extends StatelessWidget {
  const _NotificationBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -120,
          child: _BlurAccent(color: const Color(0xFFDAD7FF).withValues(alpha: 0.45), size: 240),
        ),
        Positioned(
          bottom: -70,
          left: -90,
          child: _BlurAccent(color: const Color(0xFFE5E7EB).withValues(alpha: 0.55), size: 190),
        ),
      ],
    );
  }
}

class _BlurAccent extends StatelessWidget {
  const _BlurAccent({required this.color, required this.size});

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
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 90,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF777587),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                ),
          ),
        ),
        child,
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.unread,
    required this.onTap,
  });

  final _NotificationItemData item;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseBackground = unread ? const Color(0xFFF3F0FF) : Colors.white;
    final borderColor = unread ? const Color(0xFFE2DFFF) : const Color(0xFFE5E7EB);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: baseBackground.withValues(alpha: unread ? 0.9 : 1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationAvatar(item: item),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                                color: const Color(0xFF464555),
                              ),
                          children: [
                            TextSpan(
                              text: item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF191C1D),
                              ),
                            ),
                            TextSpan(text: ' ${item.message}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: unread ? const Color(0xFF4F46E5) : const Color(0xFF777587),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item});

  final _NotificationItemData item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                item.avatarUrl,
                fit: BoxFit.cover,
                colorBlendMode: item.avatarGrayscale ? BlendMode.saturation : BlendMode.srcOver,
                color: item.avatarGrayscale ? const Color(0xFF9CA3AF).withValues(alpha: 0.18) : null,
                errorBuilder: (_, __, ___) => Container(
                  color: item.avatarBackground,
                  alignment: Alignment.center,
                  child: Text(
                    item.name.isNotEmpty ? item.name.characters.first : '?',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF3123CC)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.iconBackground,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(item.icon, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF191C1D),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF464555),
                ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItemData {
  const _NotificationItemData({
    required this.id,
    required this.name,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.iconBackground,
    required this.avatarUrl,
    required this.avatarBackground,
    required this.isUnread,
    required this.type,
    this.avatarGrayscale = false,
    this.refType,
    this.refId,
  });

  final String id;
  final String name;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color iconBackground;
  final String avatarUrl;
  final Color avatarBackground;
  final bool isUnread;
  final String type;
  final bool avatarGrayscale;
  final String? refType;
  final String? refId;

  _NotificationItemData copyWith({bool? isUnread}) {
    return _NotificationItemData(
      id: id,
      name: name,
      message: message,
      timeAgo: timeAgo,
      icon: icon,
      iconBackground: iconBackground,
      avatarUrl: avatarUrl,
      avatarBackground: avatarBackground,
      isUnread: isUnread ?? this.isUnread,
      type: type,
      avatarGrayscale: avatarGrayscale,
      refType: refType,
      refId: refId,
    );
  }
}