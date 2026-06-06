import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../app/di.dart';
import '../../core/services/notification_service.dart';
import '../../features/feed/presentation/screens/notification_screen.dart';

class NotificationBell extends StatefulWidget {
  final Color? iconColor;

  const NotificationBell({super.key, this.iconColor});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadCount();
    _subscription = getIt<NotificationService>().onForegroundMessage.listen((_) {
      if (mounted) _loadCount();
    });
  }

  Future<void> _loadCount() async {
    try {
      final response = await getIt<Dio>().get('/notifications/unread-count');
      if (mounted) {
        setState(() {
          _unreadCount = response.data['data']['count'] ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: widget.iconColor ?? theme.colorScheme.onSurfaceVariant),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ).then((_) {
              if (mounted) _loadCount();
            });
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
