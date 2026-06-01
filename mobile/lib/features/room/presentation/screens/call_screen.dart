import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/webrtc_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../bloc/room_detail_bloc.dart';
import '../bloc/room_detail_state.dart';
import '../../data/models/room_model.dart';

class CallScreen extends StatefulWidget {
  final WebRTCService webrtcService;
  final String roomId;

  const CallScreen({
    super.key,
    required this.webrtcService,
    required this.roomId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isInitializing = true;
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCall();
    
    widget.webrtcService.onMediaStateChanged.listen((_) {
      if (mounted) setState(() {});
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  String get _formattedTime {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _initCall() async {
    final authState = context.read<AuthBloc>().state;
    String currentUserId = 'unknown';
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    }
    
    await widget.webrtcService.init(currentUserId);
    await widget.webrtcService.joinCall(widget.roomId);
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.webrtcService.leaveCall();
    super.dispose();
  }

  void _toggleMute() {
    widget.webrtcService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleCamera() {
    widget.webrtcService.toggleCamera();
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  void _endCall() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final remoteRenderers = widget.webrtcService.remoteRenderers.values.toList();
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Nền tối slate hiện đại
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Ánh sáng trang trí nền
            Positioned(
              top: -100,
              left: -100,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.indigo.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            
            // Lưới Video tất cả người tham gia (Meet Style)
            if (_isInitializing)
              _buildWaitingScreen()
            else
              _buildMeetGrid(widget.webrtcService.remoteRenderers.entries.toList()),

            // Header - Nút Back và Tiêu đề Call
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _buildGlassButton(
                    icon: Icons.keyboard_arrow_down,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "${remoteRenderers.length + 1}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                          _formattedTime,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toolbar điều khiển 5 nút
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                          icon: Icons.chat_bubble_outline,
                          isActive: false,
                          activeColor: Colors.white,
                          onTap: () {
                            // pop to chat
                            Navigator.of(context).pop();
                          },
                        ),
                        _buildToolButton(
                          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam_outlined,
                          isActive: _isCameraOff,
                          activeColor: Colors.redAccent,
                          onTap: _toggleCamera,
                        ),
                        _buildToolButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic_none,
                          isActive: _isMuted,
                          activeColor: Colors.redAccent,
                          onTap: _toggleMute,
                        ),
                        _buildToolButton(
                          icon: Icons.screen_share_outlined,
                          isActive: false,
                          activeColor: Colors.white,
                          onTap: () {
                            // Screen share logic (placeholder)
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng chia sẻ màn hình đang phát triển')));
                          },
                        ),
                        _buildCallEndButton(onTap: _endCall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Màn hình chờ phong cách hiện đại
  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_outlined, size: 64, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            "Đang chờ mọi người tham gia...",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Render lưới camera xịn xò (Meet Style)
  Widget _buildMeetGrid(List<MapEntry<String, RTCVideoRenderer>> remoteEntries) {
    // remoteEntries: userId -> renderer
    final count = remoteEntries.length + 1; // +1 cho local
    final size = MediaQuery.of(context).size;
    
    int crossAxisCount = 1;
    double aspectRatio = 1.0;
    
    if (count == 1) {
      crossAxisCount = 1;
      aspectRatio = size.width / size.height;
    } else if (count == 2) {
      crossAxisCount = 1;
      aspectRatio = size.width / (size.height / 2);
    } else if (count <= 4) {
      crossAxisCount = 2;
      aspectRatio = (size.width / 2) / (size.height / 2.5);
    } else {
      crossAxisCount = 3;
      aspectRatio = (size.width / 3) / (size.width / 3);
    }

    return BlocBuilder<RoomDetailBloc, RoomDetailState>(
      buildWhen: (p, c) => c is MembersLoaded || c is RoomDetailLoaded,
      builder: (context, state) {
        final members = context.read<RoomDetailBloc>().currentMembers;

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            final isLocal = index == 0;
            RTCVideoRenderer renderer;
            String? userId;
            String displayName = "Người dùng";
            String? avatarUrl;
            bool isVideoOn = true;

            if (isLocal) {
              renderer = widget.webrtcService.localRenderer;
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                userId = authState.user.id;
                displayName = authState.user.fullName ?? authState.user.username;
                avatarUrl = authState.user.avatarUrl;
              }
              isVideoOn = !_isCameraOff;
              displayName = "Bạn ($displayName)";
            } else {
              final entry = remoteEntries[index - 1];
              userId = entry.key;
              renderer = entry.value;
              
              final member = members.where((m) => m.userId == userId).firstOrNull;
              if (member != null) {
                displayName = member.fullName ?? member.username ?? "Thành viên";
                avatarUrl = member.avatarUrl;
              } else {
                displayName = "Thành viên $index";
              }
              
              // Check nếu video tắt (không có track hoặc track bị disabled/muted)
              final videoTracks = renderer.srcObject?.getVideoTracks() ?? [];
              if (videoTracks.isEmpty) {
                isVideoOn = false;
              } else {
                // WebRTC có thể thay đổi trạng thái track
                isVideoOn = videoTracks.first.enabled && !(videoTracks.first.muted ?? false);
              }
            }

            return Container(
              color: const Color(0xFF1E293B), // Nền xám đậm khi tắt cam
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideoOn)
                    RTCVideoView(
                      renderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: isLocal,
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomAvatar(
                            imageUrl: avatarUrl,
                            name: displayName,
                            radius: 40,
                            backgroundColor: Colors.indigo.shade400,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (isLocal && _isMuted)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_off, color: Colors.redAccent, size: 16),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildCallEndButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
    );
  }
}
