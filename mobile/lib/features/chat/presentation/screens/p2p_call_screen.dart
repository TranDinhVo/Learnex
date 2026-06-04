import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../app/app.dart';
import '../../../../app/di.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/webrtc_service.dart';
import '../../../../core/services/call_manager.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class P2PCallScreen extends StatefulWidget {
  final WebRTCService webrtcService;
  final String roomId;
  final String partnerName;
  final String partnerId;
  final bool isAudioOnly;
  final bool isCaller;

  const P2PCallScreen({
    super.key,
    required this.webrtcService,
    required this.roomId,
    required this.partnerName,
    required this.partnerId,
    this.isAudioOnly = false,
    this.isCaller = false,
  });

  @override
  State<P2PCallScreen> createState() => _P2PCallScreenState();
}

class _P2PCallScreenState extends State<P2PCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  late bool _isCameraOff;
  bool _isInitializing = true;
  Offset _localVideoPosition = const Offset(16, 16);
  bool _isConnected = false;
  Timer? _timer;
  int _secondsElapsed = 0;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _mediaSubscription;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _isCameraOff = widget.isAudioOnly;

    // Đăng ký cuộc gọi với CallManager
    CallManager.instance.startCall(ActiveCallInfo(
      roomId: widget.roomId,
      partnerName: widget.partnerName,
      partnerId: widget.partnerId,
      isAudioOnly: widget.isAudioOnly,
      isCaller: widget.isCaller,
    ));

    _initCall();

    _wsSubscription =
        getIt<WebSocketService>().messages.listen((message) {
      if (!mounted) return;
      // Tín hiệu kết thúc / từ chối cuộc gọi giờ đã được xử lý toàn cục ở app.dart
      // Nên P2PCallScreen không cần gọi _endCall nữa để tránh conflict / double pop.
    });

    _mediaSubscription =
        widget.webrtcService.onMediaStateChanged.listen((_) {
      if (mounted) {
        final wasConnected = _isConnected;
        setState(() {
          _isConnected =
              widget.webrtcService.remoteRenderers.isNotEmpty;
        });
        if (!wasConnected && _isConnected) {
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String get _formattedTime {
    final m = (_secondsElapsed / 60).floor().toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _initCall() async {
    final authState = context.read<AuthBloc>().state;
    String currentUserId = 'unknown';
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    }

    await widget.webrtcService.init(
      currentUserId,
      audioOnly: widget.isAudioOnly,
    );
    await widget.webrtcService.joinPrivateCall(
      roomId: widget.roomId,
      partnerId: widget.partnerId,
      isCaller: widget.isCaller,
    );

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsSubscription?.cancel();
    _mediaSubscription?.cancel();
    // Chỉ leaveCall nếu không minimize (tức là thực sự kết thúc)
    if (!CallManager.instance.isMinimized) {
      widget.webrtcService.leaveCall();
      CallManager.instance.endCall();
    }
    super.dispose();
  }

  void _toggleMute() {
    widget.webrtcService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleCamera() {
    if (widget.isAudioOnly) return;
    widget.webrtcService.toggleCamera();
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  void _toggleSpeaker() {
    // Toggle speaker on/off (audio-only mode)
    widget.webrtcService.toggleSpeaker();
    setState(() {});
  }

  void _sendStatusHelper(String statusStr) {
    if (!mounted) return;
    final typeStr = widget.isAudioOnly ? 'VOICE' : 'VIDEO';
    context.read<ChatBloc>().add(SendMessageEvent(
          conversationId: widget.partnerId,
          content: '[CALL_HISTORY]:$typeStr:$statusStr',
        ));
  }

  /// Kết thúc cuộc gọi hoàn toàn
  void _endCall({bool isCaller = true, bool notify = true}) {
    if (_isDisposing) return;
    _isDisposing = true;

    final wsService = getIt<WebSocketService>();
    if (notify) {
      wsService.send({
        'type': 'private_call_end',
        'data': {'targetId': widget.partnerId, 'roomId': widget.roomId}
      });
      wsService.send({
        'type': 'leave_call',
        'data': {'roomId': widget.roomId}
      });
    }

    final statusStr =
        _isConnected ? _secondsElapsed.toString() : 'MISSED';
    if (isCaller) {
      _sendStatusHelper(statusStr);
    }

    _timer?.cancel();
    widget.webrtcService.leaveCall();
    CallManager.instance.endCall();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Thu nhỏ màn hình cuộc gọi (như Zalo / Google Meet)
  void _minimizeCall() {
    final overlayState = Overlay.of(context);
    CallManager.instance.minimizeCall(
      overlayState: overlayState,
      webrtcService: widget.webrtcService,
      onRestore: () {
        // Mở lại màn hình cuộc gọi
        globalNavigatorKey.currentState!.push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => P2PCallScreen(
              webrtcService: widget.webrtcService,
              roomId: widget.roomId,
              partnerName: widget.partnerName,
              partnerId: widget.partnerId,
              isAudioOnly: widget.isAudioOnly,
              isCaller: widget.isCaller,
            ),
          ),
        );
      },
      onEnd: () {
        _endCall(isCaller: true);
      },
    );
    // Pop nhưng không dispose WebRTC
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAudioOnly) {
      return _buildVoiceCallUI(context);
    }
    return _buildVideoCallUI(context);
  }

  Widget _buildVoiceCallUI(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimizeCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1B4B),
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: minimize + end
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildGlassButton(
                      icon: Icons.keyboard_arrow_down,
                      onTap: _minimizeCall,
                    ),
                    const Spacer(),
                    if (_isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Cuộc gọi thoại',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Text(
                widget.partnerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isConnected ? _formattedTime : 'Đang kết nối...',
                style: TextStyle(
                  color: _isConnected ? Colors.white : Colors.white54,
                  fontSize: _isConnected ? 20 : 15,
                  fontWeight: _isConnected
                      ? FontWeight.w600
                      : FontWeight.normal,
                  letterSpacing: _isConnected ? 2.0 : 0,
                ),
              ),
              const Spacer(),
              // Animated Avatar
              _buildAnimatedAvatar(),
              const Spacer(),
              _buildVoiceToolbar(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (!_isConnected) ...[
          // Pulse rings when connecting
          ...List.generate(3, (i) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.3 + i * 0.15),
              duration: Duration(milliseconds: 1500 + i * 300),
              curve: Curves.easeOut,
              builder: (_, scale, __) => Transform.scale(
                scale: scale,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.indigo.withValues(alpha: 0.08 - i * 0.02),
                    border: Border.all(
                        color: Colors.indigo.withValues(alpha: 0.15 - i * 0.04),
                        width: 1),
                  ),
                ),
              ),
            );
          }),
        ],
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.indigo.shade400,
            border: Border.all(color: Colors.white24, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.partnerName.isNotEmpty
                ? widget.partnerName[0].toUpperCase()
                : 'U',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic_none,
            label: _isMuted ? 'Bỏ tắt' : 'Tắt mic',
            isActive: _isMuted,
            activeColor: Colors.redAccent,
            onTap: _toggleMute,
          ),
          _buildCallEndButton(onTap: () => _endCall(isCaller: true)),
          _buildToolButton(
            icon: Icons.volume_up_outlined,
            label: 'Loa ngoài',
            isActive: false,
            activeColor: Colors.blueAccent,
            onTap: _toggleSpeaker,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallUI(BuildContext context) {
    final remoteRenderers =
        widget.webrtcService.remoteRenderers.values.toList();
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimizeCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              // Background accent light
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.indigo.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Remote Video
              if (_isInitializing || remoteRenderers.isEmpty)
                _buildWaitingScreen()
              else
                Positioned.fill(
                  child: RTCVideoView(
                    remoteRenderers.first,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),

              // Local Video (draggable)
              if (!_isCameraOff && !_isInitializing)
                Positioned(
                  right: _localVideoPosition.dx,
                  bottom: _localVideoPosition.dy + 120,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _localVideoPosition = Offset(
                          (_localVideoPosition.dx - details.delta.dx)
                              .clamp(16.0, screenSize.width - 136),
                          (_localVideoPosition.dy - details.delta.dy)
                              .clamp(16.0, screenSize.height - 290),
                        );
                      });
                    },
                    child: Container(
                      width: 120,
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RTCVideoView(
                            widget.webrtcService.localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                          if (_isMuted)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mic_off,
                                    color: Colors.redAccent, size: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Header: Minimize + Timer
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _buildGlassButton(
                      icon: Icons.keyboard_arrow_down,
                      onTap: _minimizeCall,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnected ? _formattedTime : '00:00',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Toolbar
              Positioned(
                bottom: 30,
                left: 30,
                right: 30,
                child: _buildVideoToolbar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic_none,
            label: _isMuted ? 'Bỏ tắt' : 'Mic',
            isActive: _isMuted,
            activeColor: Colors.redAccent,
            onTap: _toggleMute,
          ),
          _buildCallEndButton(onTap: () => _endCall(isCaller: true)),
          _buildToolButton(
            icon: _isCameraOff
                ? Icons.videocam_off
                : Icons.videocam_outlined,
            label: _isCameraOff ? 'Bật cam' : 'Camera',
            isActive: _isCameraOff,
            activeColor: Colors.redAccent,
            onTap: _toggleCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 64, color: Colors.indigoAccent),
            ),
            const SizedBox(height: 24),
            Text(
              widget.partnerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang gọi...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 44,
          height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallEndButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 4),
          Text(
            'Kết thúc',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
