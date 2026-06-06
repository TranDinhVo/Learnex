import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/feed/presentation/bloc/feed_bloc.dart';
import '../features/folder/presentation/bloc/document_bloc.dart';
import '../features/friends/presentation/bloc/friend_bloc.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/story/presentation/bloc/story_bloc.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../core/services/notification_service.dart';
import '../core/services/websocket_service.dart';
import '../core/services/audio_service.dart';
import '../core/services/webrtc_service.dart';
import '../features/chat/presentation/widgets/incoming_call_overlay.dart';
import '../features/chat/presentation/screens/p2p_call_screen.dart';
import '../features/room/presentation/screens/call_screen.dart';
import '../features/room/presentation/bloc/room_detail_bloc.dart';
import '../features/room/presentation/bloc/room_detail_event.dart';
import '../core/services/call_manager.dart';
import 'dart:async';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

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
        // Phát âm thanh thông báo
        getIt<AudioService>().playMessageSound();
        
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
        BlocProvider<StoryBloc>(
          create: (_) => getIt<StoryBloc>(),
        ),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'LearnEx',
        navigatorKey: globalNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3525CD),
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        ),
        home: const SplashScreen(),
        builder: (context, child) {
          return GlobalCallListener(child: child!);
        },
      ),
    );
  }
}

class GlobalCallListener extends StatefulWidget {
  final Widget child;
  const GlobalCallListener({super.key, required this.child});

  @override
  State<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends State<GlobalCallListener> {
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    final wsService = getIt<WebSocketService>();
    _wsSubscription = wsService.messages.listen((message) {
      if (message['type'] == 'private_call_invite') {
        final data = message['data'];
        final String callerName = data['callerName'] ?? 'Người gọi';
        final String callType = data['callType'] ?? 'voice';
        final String roomId = data['roomId'];
        final String callerId = data['callerId'];

        if (globalNavigatorKey.currentState?.overlay != null) {
          OverlayHelper.showIncomingCall(
            overlayState: globalNavigatorKey.currentState!.overlay!,
            callerName: callerName,
            callType: callType,
            onAccept: () {
              // Send accept
              wsService.send({
                'type': 'private_call_accept',
                'data': {'callerId': callerId, 'roomId': roomId}
              });
              // Open screen
              globalNavigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (_) => P2PCallScreen(
                    webrtcService: getIt<WebRTCService>(),
                    roomId: roomId,
                    partnerName: callerName,
                    partnerId: callerId,
                    isAudioOnly: callType == 'voice',
                    isCaller: false,
                  ),
                ),
              );
            },
            onDecline: () {
              wsService.send({
                'type': 'private_call_reject',
                'data': {'callerId': callerId}
              });
            },
          );
        }
      } else if (message['type'] == 'room_call_invite') {
        final data = message['data'];
        final String callerName = data['callerName'] ?? 'Thành viên';
        final String callType = data['callType'] ?? 'video';
        final String roomId = data['roomId'];

        if (globalNavigatorKey.currentState?.overlay != null) {
          OverlayHelper.showIncomingCall(
            overlayState: globalNavigatorKey.currentState!.overlay!,
            callerName: callerName,
            callType: callType,
            onAccept: () {
              globalNavigatorKey.currentState!.push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => getIt<RoomDetailBloc>()..add(LoadRoomDetailEvent(roomId)),
                    child: CallScreen(
                      webrtcService: getIt<WebRTCService>(),
                      roomId: roomId,
                    ),
                  ),
                ),
              );
            },
            onDecline: () {
              // Only hide overlay, no need to send reject to others in a group call
            },
          );
        }
      } else if (message['type'] == 'private_call_accept') {
        // Có thể bắt thêm nếu muốn mở trực tiếp bên người gọi
        // Tuy nhiên người gọi đã nằm sẵn ở p2p_call_screen.dart chờ rồi (nếu làm đúng logic)
      } else if (message['type'] == 'private_call_reject' || message['type'] == 'user_left_call' || message['type'] == 'private_call_end') {
         OverlayHelper.hideIncomingCall();
         
         // Xử lý buộc kết thúc cuộc gọi 1-1 từ xa
         final callInfo = CallManager.instance.activeCall;
         if (callInfo != null && !callInfo.isRoomCall) {
            getIt<WebRTCService>().leaveCall();
            
            // Nếu màn hình Call đang bật (không thu nhỏ), tự động tắt nó
            if (!CallManager.instance.isMinimized && globalNavigatorKey.currentState != null) {
                globalNavigatorKey.currentState!.pop();
            }
            
            CallManager.instance.endCall();
         }
      } else if (message['type'] == 'new_notification') {
        final notif = message['data'];
        if (notif['type'] == 'room_join_request') {
          if (globalNavigatorKey.currentContext != null) {
            ScaffoldMessenger.of(globalNavigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text(notif['body'] ?? 'Có yêu cầu tham gia phòng mới'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Xem',
                  textColor: Colors.yellow,
                  onPressed: () {
                    // Cần push tới RoomRequestsScreen
                    // Do roomId được lưu trong ref_id
                    final roomId = notif['ref_id'];
                    if (roomId != null) {
                      // Navigate to RoomDetailScreen where user can see it
                      // Wait, we don't have RoomDetailBloc globally available to push directly to Requests,
                      // but we can push to RoomDetailScreen and let them open it.
                    }
                  },
                ),
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}