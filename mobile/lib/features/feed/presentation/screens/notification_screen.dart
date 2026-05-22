import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final List<_NotificationItemData> _newNotifications;
  final List<_NotificationItemData> _olderNotifications = const [
    _NotificationItemData(
      name: 'Minh Hoàng',
      message: 'đã đăng một tài liệu mới trong lớp Lịch sử kiến trúc.',
      timeAgo: '2 giờ trước',
      icon: Icons.school,
      iconBackground: Color(0xFF58579B),
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBXOF6SeKkFCHdOtPiTVupXVCxOVPBplDwV11hu3CZ59DxMRjB1xn-FeofUPAlPSBmcyEW-a3N3im8skltO_-_px0T-TlCNIXe69fesrfHDQJ2jew3h1G0DMDk-fJc2qrECyTfi00G1OtKGJpJxtFDx4RQcH1O879Vy_IyBooovZjntO_NgVa5isPHZOVkRQH-JgmgoZtUfiLkHUe41-wXoJ-DZpk0aKKlwmeRAdLlMxaCODcu-EdsnSX8BH4DMjUSoyPGbIS83s58',
      avatarBackground: Color(0xFFF3F4F5),
      isUnread: false,
      avatarGrayscale: true,
    ),
    _NotificationItemData(
      name: 'Mai Anh',
      message: 'đã chia sẻ bài viết của bạn với nhóm Nghiên cứu.',
      timeAgo: '5 giờ trước',
      icon: Icons.share,
      iconBackground: Color(0xFFC3C0FF),
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAYJMeOYtRPb6Flavl75hTAc64pjv5L8QIcVwjNdiPj7Tfdxp03cUS3uPK4QW_x6_lAlaMb6PYMu3RzeV658j0JaUqV9Q12vyDs8r_y_uTrGyJ67qvOHqtBzqYp4vaVsFbaQB7sTgDb2Ah6Pf58VkhCHsOajnsCow7SIIBF6Z5BdtyRIzZY75mhaxrHYe9qWkcIj2Y3ojXX55bg_EXC6EH8tYVKpxB7IfwNdy_Ov5B9MBvW-9b3K7sK5l_7Gc9YZIB56H8_qqomO6k',
      avatarBackground: Color(0xFFF3F4F5),
      isUnread: false,
      avatarGrayscale: true,
    ),
    _NotificationItemData(
      name: 'Đức Anh',
      message: 'đã bình luận vào bài đăng của bạn.',
      timeAgo: 'Hôm qua',
      icon: Icons.star,
      iconBackground: Color(0xFFA44100),
      avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA6gK6o_O4QbIq6filgWaFi2eEhs1VayTdjzwzd-t1MZ9otWF2cE1aPsky5EeGRrjm0QfW05lVfWqArkqi8iCpDeM5SvrXbXO0tJpLutP1rv4PcIPqIGLPqoi0btUCnSHYrIHsA6FwiVYZFfWTyLTIYkGqww40Pfsi5JZKNgH1O4I63J4fXcY4_mzX43JsABh7e64_Icrvl_MTZMPdNSiqwNxmzLnRZAoBd4fCvLahafIR5oipvNs4SOxdJM9zRipUhnBel6cb8xKY',
      avatarBackground: Color(0xFFF3F4F5),
      isUnread: false,
      avatarGrayscale: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _newNotifications = [
      _NotificationItemData(
        name: 'Anh Nam',
        message: 'đã thích bài đăng của bạn',
        timeAgo: '2 phút trước',
        icon: Icons.favorite,
        iconBackground: const Color(0xFFBA1A1A),
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCc3pB7Js-XMXn3M73Mta3J05tck9CvIJj58efRGnKYOD0m4Q5HpDqtbi7xD9tYvly59vTBpkNj7hxtFl7hbMVQITP7ALFXQwjgr-S6eADztqSU0GY5vNYgmaaTxDg854gVdqgQQV_FDZnyXjmzo_kf0kXgBXPOAv6pe1b5c6R1lg6Z7sSpQ-0c3ecLrVhcp43KHXA9AyIzwx4nKEphCPV-kQbM94i_PMsOyauGqIMDf7e6pPmUdcREAHJcdVq82nCqA83dSaN18Ik',
        avatarBackground: const Color(0xFFEDEEFF),
        isUnread: true,
      ),
      _NotificationItemData(
        name: 'Thanh Trúc',
        message: 'đã bình luận về bộ sưu tập Tài liệu Toán học của bạn.',
        timeAgo: '15 phút trước',
        icon: Icons.chat_bubble,
        iconBackground: const Color(0xFF3525CD),
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAPm7lEktsbDzk-AqrFLqosJrFyPIeDHfYDzGgAQw-DKPKI9ip88YhdQoLt_le_2eQ5l65p3LQu4uHM6Ke19a0sjQV7rUXL9k3BCa9__F_ujChen45yvgkQ4vrfzKbin3YKb08ZEcJYkVD3_NPNKyMZKTuvpxYEifnWizHEuCopu-zMgg57_RSrTfYiETWggXczffQ8Q_CARaQO8iPsTwppIAlmi6UprQqeoIprRXkwkxsxg9KlsH08b60Fk8_2p6Z2IXstKMEoth0',
        avatarBackground: const Color(0xFFEDEEFF),
        isUnread: true,
      ),
    ];
  }

  List<_NotificationItemData> get _visibleNewNotifications =>
      _newNotifications.where((item) => item.isUnread).toList(growable: false);

  void _markAllAsRead() {
    setState(() {
      _newNotifications.replaceRange(
        0,
        _newNotifications.length,
        _newNotifications.map((item) => item.copyWith(isUnread: false)).toList(growable: false),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _visibleNewNotifications.length;

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
                  icon: const Icon(Icons.arrow_back),
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _NotificationSection(
                        title: 'Mới',
                        child: Column(
                          children: [
                            if (_visibleNewNotifications.isEmpty)
                              const _EmptyStateCard(
                                icon: Icons.notifications_off_outlined,
                                title: 'Không còn thông báo mới',
                                subtitle: 'Những cập nhật mới sẽ xuất hiện ở đây.',
                              )
                            else
                              ..._visibleNewNotifications.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NotificationTile(item: item, unread: true),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _NotificationSection(
                        title: 'Trước đó',
                        child: Column(
                          children: [
                            ..._olderNotifications.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _NotificationTile(item: item, unread: false),
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
  const _NotificationTile({required this.item, required this.unread});

  final _NotificationItemData item;
  final bool unread;

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
          onTap: () {},
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
            child: Icon(icon, color: Color(0xFF4F46E5)),
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
    required this.name,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.iconBackground,
    required this.avatarUrl,
    required this.avatarBackground,
    required this.isUnread,
    this.avatarGrayscale = false,
  });

  final String name;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color iconBackground;
  final String avatarUrl;
  final Color avatarBackground;
  final bool isUnread;
  final bool avatarGrayscale;

  _NotificationItemData copyWith({bool? isUnread}) {
    return _NotificationItemData(
      name: name,
      message: message,
      timeAgo: timeAgo,
      icon: icon,
      iconBackground: iconBackground,
      avatarUrl: avatarUrl,
      avatarBackground: avatarBackground,
      isUnread: isUnread ?? this.isUnread,
      avatarGrayscale: avatarGrayscale,
    );
  }
}