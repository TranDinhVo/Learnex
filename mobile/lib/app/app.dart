import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/feed/presentation/bloc/feed_bloc.dart';
import '../features/folder/presentation/bloc/document_bloc.dart';
import '../features/friends/presentation/bloc/friend_bloc.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../core/services/notification_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Initialize Notification Service
    final notificationService = getIt<NotificationService>();
    notificationService.initialize();
    
    // Listen for foreground messages
    notificationService.onForegroundMessage.listen((message) {
      if (message.notification != null) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification?.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(message.notification?.body ?? ''),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF4F46E5),
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(CheckAuthEvent()),
        ),
        BlocProvider<FeedBloc>(
          create: (_) => getIt<FeedBloc>(),
        ),
        BlocProvider<DocumentBloc>(
          create: (_) => getIt<DocumentBloc>(),
        ),
        BlocProvider<FriendBloc>(
          create: (_) => getIt<FriendBloc>(),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => getIt<ChatBloc>(),
        ),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'LearnEx',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3525CD),
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}