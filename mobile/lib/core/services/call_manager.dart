import 'dart:async';  
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_service.dart';

/// Trạng thái của một cuộc gọi đang hoạt động
class ActiveCallInfo {
  final String roomId;
  final String partnerName;
  final String partnerId;
  final bool isAudioOnly;
  final bool isCaller;

  final bool isRoomCall;
  final int Function()? getParticipantCount;

  const ActiveCallInfo({
    required this.roomId,
    required this.partnerName,
    required this.partnerId,
    required this.isAudioOnly,
    required this.isCaller,
    this.isRoomCall = false,
    this.getParticipantCount,
  });
}

/// Quản lý trạng thái cuộc gọi toàn cục
/// Cho phép thu nhỏ cuộc gọi (minimize) như Zalo/Google Meet
class CallManager {
  CallManager._();
  static final CallManager instance = CallManager._();

  // Cuộc gọi đang hoạt động
  ActiveCallInfo? _activeCall;
  ActiveCallInfo? get activeCall => _activeCall;
  bool get hasActiveCall => _activeCall != null;

  // Stream để notify UI khi trạng thái thay đổi
  final StreamController<ActiveCallInfo?> _callStateController =
      StreamController.broadcast();
  Stream<ActiveCallInfo?> get callStateStream => _callStateController.stream;

  // Overlay entry cho mini call window
  OverlayEntry? _miniCallOverlay;
  bool _isMinimized = false;
  bool get isMinimized => _isMinimized;

  // Callback để navigate trở lại màn hình cuộc gọi
  VoidCallback? _onRestoreCall;
  VoidCallback? _onEndCall;

  /// Bắt đầu tracking một cuộc gọi mới
  void startCall(ActiveCallInfo info) {
    _activeCall = info;
    _isMinimized = false;
    _callStateController.add(info);
  }

  /// Kết thúc cuộc gọi và dọn dẹp
  void endCall() {
    _activeCall = null;
    _isMinimized = false;
    _removeMiniOverlay();
    _callStateController.add(null);
    _onRestoreCall = null;
    _onEndCall = null;
  }

  /// Thu nhỏ màn hình cuộc gọi và hiển thị floating mini window
  void minimizeCall({
    required OverlayState overlayState,
    required VoidCallback onRestore,
    required VoidCallback onEnd,
    required WebRTCService webrtcService,
  }) {
    if (_activeCall == null) return;
    _isMinimized = true;
    _onRestoreCall = onRestore;
    _onEndCall = onEnd;
    _showMiniOverlay(overlayState, webrtcService);
  }

  /// Khôi phục màn hình cuộc gọi từ mini window
  void restoreCall() {
    _removeMiniOverlay();
    _isMinimized = false;
    _onRestoreCall?.call();
  }

  void _showMiniOverlay(OverlayState overlayState, WebRTCService webrtcService) {
    _removeMiniOverlay();
    _miniCallOverlay = OverlayEntry(
      builder: (context) => _MiniCallWindow(
        callInfo: _activeCall!,
        webrtcService: webrtcService,
        onTap: () {
          restoreCall();
        },
        onEnd: () {
          _onEndCall?.call();
          endCall();
        },
      ),
    );
    overlayState.insert(_miniCallOverlay!);
  }

  void _removeMiniOverlay() {
    _miniCallOverlay?.remove();
    _miniCallOverlay = null;
  }
}

/// Widget hiển thị cửa sổ cuộc gọi thu nhỏ (floating mini window)
class _MiniCallWindow extends StatefulWidget {
  final ActiveCallInfo callInfo;
  final WebRTCService webrtcService;
  final VoidCallback onTap;
  final VoidCallback onEnd;

  const _MiniCallWindow({
    required this.callInfo,
    required this.webrtcService,
    required this.onTap,
    required this.onEnd,
  });

  @override
  State<_MiniCallWindow> createState() => _MiniCallWindowState();
}

class _MiniCallWindowState extends State<_MiniCallWindow>
    with TickerProviderStateMixin {
  Offset _position = const Offset(16, 100);
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_seconds / 60).floor().toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isVideoOff = widget.callInfo.isAudioOnly;

    // Get primary video renderer to display (remote or local)
    RTCVideoRenderer? primaryRenderer;
    if (!isVideoOff) {
      if (widget.webrtcService.remoteRenderers.isNotEmpty) {
        primaryRenderer = widget.webrtcService.remoteRenderers.values.first;
      } else {
        primaryRenderer = widget.webrtcService.localRenderer;
      }
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx)
                  .clamp(0.0, screenSize.width - 120),
              (_position.dy + details.delta.dy)
                  .clamp(0.0, screenSize.height - 180),
            );
          });
        },
        onTap: widget.onTap,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 120,
            height: 180,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (primaryRenderer != null)
                  RTCVideoView(
                    primaryRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    mirror: primaryRenderer == widget.webrtcService.localRenderer,
                  )
                else
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.callInfo.isRoomCall ? Colors.teal.shade400 : Colors.indigo.shade400,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: widget.callInfo.isRoomCall
                          ? const Icon(Icons.people, color: Colors.white, size: 24)
                          : Text(
                              widget.callInfo.partnerName.isNotEmpty
                                  ? widget.callInfo.partnerName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                // Tappable overlay for the whole window to maximize
                Positioned.fill(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

                  // Name and Timer overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.callInfo.partnerName,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formattedTime,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // End call button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: widget.onEnd,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
