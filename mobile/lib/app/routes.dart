import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/feed/presentation/screens/create_post_screen.dart';
import '../features/feed/presentation/screens/notification_screen.dart';
import '../features/folder/presentation/screens/folder_overview_screen.dart';
import '../features/folder/presentation/screens/add_document_screen.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_detail_screen.dart';
import '../features/room/presentation/screens/room_list_screen.dart';
import '../features/room/presentation/screens/room_detail_screen.dart';
import '../features/room/presentation/screens/call_screen.dart';
import '../features/friends/presentation/screens/friends_screen.dart';
import '../app/di.dart';
import '../core/services/webrtc_service.dart';
import '../shared/widgets/app_bottom_nav_bar.dart';

/// Các route path constants
class RoutePaths {
  const RoutePaths._();
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String feed = '/feed';
  static const String createPost = '/feed/create';
  static const String postDetail = '/feed/post/:id';
  static const String notifications = '/notifications';
  static const String folders = '/folders';
  static const String folderDetail = '/folders/:id';
  static const String addDocument = '/folders/add-document';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:id';
  static const String rooms = '/rooms';
  static const String roomDetail = '/rooms/:id';
  static const String videoCall = '/video-call';
  static const String incomingCall = '/incoming-call';
  static const String profile = '/profile';
  static const String friends = '/friends';
}

/// Scaffold có bottom nav bar dùng chung cho các tab chính
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onHomeTap: () => context.go(RoutePaths.feed),
        onFolderTap: () => context.go(RoutePaths.folders),
        onAddTap: () => context.push(RoutePaths.createPost),
        onChatTap: () => context.go(RoutePaths.chat),
        onMeetingTap: () => context.go(RoutePaths.rooms),
      ),
    );
  }
}

/// Navigator keys cho shell route
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Router chính của ứng dụng.
///
/// Redirect logic: nếu chưa đăng nhập → /login.
/// Shell route bao bọc 5 tab chính với bottom nav.
GoRouter createRouter({
  required bool isAuthenticated,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final isOnAuthPage = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register ||
          state.matchedLocation == RoutePaths.forgotPassword ||
          state.matchedLocation == RoutePaths.otpVerification ||
          state.matchedLocation == RoutePaths.splash;

      // Chưa đăng nhập + không ở trang auth → redirect về login
      if (!isAuthenticated && !isOnAuthPage) {
        return RoutePaths.login;
      }

      // Đã đăng nhập + đang ở login/register → redirect về feed
      if (isAuthenticated &&
          (state.matchedLocation == RoutePaths.login ||
              state.matchedLocation == RoutePaths.register)) {
        return RoutePaths.feed;
      }

      return null; // Không redirect
    },
    routes: [
      // ── Splash ──
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth routes (không có bottom nav) ──
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.otpVerification,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),

      // ── Shell route: 5 tab chính ──
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // Xác định tab index dựa trên path
          int index = 0;
          final location = state.matchedLocation;
          if (location.startsWith('/folders')) {
            index = 1;
          } else if (location.startsWith('/chat')) {
            index = 3;
          } else if (location.startsWith('/rooms')) {
            index = 4;
          }
          return ScaffoldWithBottomNav(
            currentIndex: index,
            child: child,
          );
        },
        routes: [
          // Tab 0: Feed
          GoRoute(
            path: RoutePaths.feed,
            builder: (context, state) => const FeedScreen(),
          ),

          // Tab 1: Folders
          GoRoute(
            path: RoutePaths.folders,
            builder: (context, state) => const FolderOverviewScreen(),
          ),

          // Tab 3: Chat
          GoRoute(
            path: RoutePaths.chat,
            builder: (context, state) => const ChatListScreen(),
          ),

          // Tab 4: Rooms
          GoRoute(
            path: RoutePaths.rooms,
            builder: (context, state) => const RoomListScreen(),
          ),
        ],
      ),

      // ── Routes không nằm trong shell (full screen) ──
      GoRoute(
        path: RoutePaths.createPost,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: RoutePaths.chatDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return const ChatDetailScreen();
        },
      ),
      GoRoute(
        path: RoutePaths.addDocument,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddDocumentScreen(),
      ),
      GoRoute(
        path: RoutePaths.roomDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RoomDetailScreen(
             roomId: id,
             roomName: extra['roomName'] as String? ?? 'Phòng Học',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.videoCall,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CallScreen(
            webrtcService: getIt<WebRTCService>(),
            roomId: extra['roomId'] as String? ?? "room_demo",
          );
        },
      ),
      GoRoute(
        path: RoutePaths.incomingCall,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return IncomingCallScreen(
            callerName: extra['callerName'] as String? ?? '',
            callerAvatar: extra['callerAvatar'] as String?,
            roomId: extra['roomId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: RoutePaths.friends,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FriendsScreen(),
      ),
    ],
  );
}

// ── (Incoming Call screen omitted for simplicity) ──

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String? callerAvatar;
  final String roomId;
  const IncomingCallScreen({super.key, required this.callerName, this.callerAvatar, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Cuộc gọi đến từ $callerName')),
    );
  }
}

